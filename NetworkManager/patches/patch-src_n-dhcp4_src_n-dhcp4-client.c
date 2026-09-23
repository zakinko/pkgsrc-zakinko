$NetBSD$

Reach the poller and the timer through the seam.

epoll and timerfd become kqueue and a timer-only kqueue; what the rest of this
file sees is unchanged - one descriptor to hand to the caller and a tag saying
which source woke it.

Two things fell out while moving.  The flags the poller reported were passed
down to n_dhcp4_client_probe_dispatch_io() and never looked at there, so they
are no longer passed.  And the dispatcher no longer inspects HUP and ERR
separately: a broken timer surfaces as a failure out of the read, which is
where it is handled now.

--- src/n-dhcp4/src/n-dhcp4-client.c.orig
+++ src/n-dhcp4/src/n-dhcp4-client.c
@@ -11,13 +11,10 @@
 #include <c-list.h>
 #include <c-stdaux.h>
 #include <errno.h>
-#include <linux/if_ether.h>
-#include <linux/if_infiniband.h>
+#include <net/if.h>
 #include <stdlib.h>
 #include <string.h>
-#include <sys/epoll.h>
 #include <sys/time.h>
-#include <sys/timerfd.h>
 #include <time.h>
 #include <unistd.h>
 #include "n-dhcp4.h"
@@ -374,9 +371,6 @@
  */
 _c_public_ int n_dhcp4_client_new(NDhcp4Client **clientp, NDhcp4ClientConfig *config) {
         _c_cleanup_(n_dhcp4_client_unrefp) NDhcp4Client *client = NULL;
-        struct epoll_event ev = {
-                .events = EPOLLIN,
-        };
         int r;
 
         c_assert(clientp);
@@ -417,22 +411,20 @@
         if (r)
                 return r;
 
-        client->fd_epoll = epoll_create1(EPOLL_CLOEXEC);
-        if (client->fd_epoll < 0)
-                return -errno;
+        r = n_dhcp4_os_poll_new(&client->fd_poll);
+        if (r)
+                return r;
 
-        client->fd_timer = timerfd_create(CLOCK_BOOTTIME, TFD_CLOEXEC | TFD_NONBLOCK);
-        if (client->fd_timer < 0 && errno == EINVAL)
-                client->fd_timer = timerfd_create(CLOCK_MONOTONIC, TFD_CLOEXEC | TFD_NONBLOCK);
-        if (client->fd_timer < 0)
-                return -errno;
+        r = n_dhcp4_os_timer_new(&client->fd_timer);
+        if (r)
+                return r;
 
-        ev.data.u32 = N_DHCP4_CLIENT_EPOLL_TIMER;
-        r = epoll_ctl(client->fd_epoll, EPOLL_CTL_ADD, client->fd_timer, &ev);
-        if (r < 0) {
+        r = n_dhcp4_os_poll_add(client->fd_poll, client->fd_timer,
+                                N_DHCP4_CLIENT_EPOLL_TIMER);
+        if (r) {
                 close(client->fd_timer);
                 client->fd_timer = -1;
-                return -errno;
+                return r;
         }
 
         *clientp = client;
@@ -449,12 +441,12 @@
                 n_dhcp4_c_event_node_free(node);
 
         if (client->fd_timer >= 0) {
-                epoll_ctl(client->fd_epoll, EPOLL_CTL_DEL, client->fd_timer, NULL);
+                n_dhcp4_os_poll_del(client->fd_poll, client->fd_timer);
                 close(client->fd_timer);
         }
 
-        if (client->fd_epoll >= 0)
-                close(client->fd_epoll);
+        if (client->fd_poll >= 0)
+                close(client->fd_poll);
 
         n_dhcp4_client_config_free(client->config);
         free(client);
@@ -630,15 +622,7 @@
                 else
                         offset = timeout - now;
 
-                r = timerfd_settime(client->fd_timer,
-                                    0,
-                                    &(struct itimerspec){
-                                        .it_value = {
-                                                .tv_sec = offset / UINT64_C(1000000000),
-                                                .tv_nsec = offset % UINT64_C(1000000000),
-                                        },
-                                    },
-                                    NULL);
+                r = n_dhcp4_os_timer_set(client->fd_timer, offset);
                 c_assert(r >= 0);
 
                 client->scheduled_timeout = timeout;
@@ -657,82 +641,47 @@
  * n_dhcp4_client_dispatch() whenever the FD is readable.
  */
 _c_public_ void n_dhcp4_client_get_fd(NDhcp4Client *client, int *fdp) {
-        *fdp = client->fd_epoll;
+        *fdp = client->fd_poll;
 }
 
-static int n_dhcp4_client_dispatch_timer(NDhcp4Client *client, struct epoll_event *event) {
-        uint64_t v, ns_now;
+static int n_dhcp4_client_dispatch_timer(NDhcp4Client *client) {
+        uint64_t ns_now;
         int r;
 
-        if (event->events & (EPOLLHUP | EPOLLERR)) {
-                /*
-                 * There is no way to handle either gracefully. If we ignored
-                 * them, we would busy-loop, so lets rather forward the error
-                 * to the caller.
-                 */
-                return -ENOTRECOVERABLE;
-        }
+        /*
+         * The poller no longer reports HUP or ERR separately - kqueue folds
+         * them into the read - and both platforms surface a broken timer as a
+         * failure out of the read below.  That is where it is handled now.
+         */
+        r = n_dhcp4_os_timer_read(client->fd_timer);
+        if (r < 0)
+                return r;
+        if (!r)
+                return 0;
 
-        if (event->events & EPOLLIN) {
-                r = read(client->fd_timer, &v, sizeof(v));
-                if (r < 0) {
-                        if (errno == EAGAIN) {
-                                /*
-                                 * There are no more pending events, so nothing
-                                 * to be done. Return to the caller.
-                                 */
-                                return 0;
-                        }
+        client->scheduled_timeout = 0;
 
-                        /*
-                         * Something failed. We use CLOCK_BOOTTIME/MONOTONIC,
-                         * so ECANCELED cannot happen. Hence, there is no error
-                         * that we could gracefully handle. Fail hard and let
-                         * the caller deal with it.
-                         */
-                        return -errno;
-                } else if (r != sizeof(v) || v == 0) {
-                        /*
-                         * Kernel guarantees 8-byte reads, and only to return
-                         * data if at least one timer triggered; fail hard if
-                         * it suddenly starts exposing unexpected behavior.
-                         */
-                        return -ENOTRECOVERABLE;
-                }
+        ns_now = n_dhcp4_gettime(CLOCK_BOOTTIME);
 
-                /*
-                 * Forward the timer-event to the active probe. Timers should
-                 * not fire if there is no probe running, but lets ignore them
-                 * for now, so probe-internals are not leaked to this generic
-                 * client dispatcher.
-                 */
-                if (client->current_probe) {
-                        /*
-                         * Read the current time *after* dispatching the timer,
-                         * to make sure we do not miss wakeups.
-                         */
-                        ns_now = n_dhcp4_gettime(CLOCK_BOOTTIME);
-
-                        r = n_dhcp4_client_probe_dispatch_timer(client->current_probe,
-                                                                ns_now);
-                        if (r)
-                                return r;
-                }
+        if (client->current_probe) {
+                r = n_dhcp4_client_probe_dispatch_timer(client->current_probe, ns_now);
+                if (r)
+                        return r;
         }
 
         return 0;
 }
 
-static int n_dhcp4_client_dispatch_io(NDhcp4Client *client, struct epoll_event *event) {
-        int r;
-
-        if (client->current_probe)
-                r = n_dhcp4_client_probe_dispatch_io(client->current_probe,
-                                                     event->events);
-        else
+static int n_dhcp4_client_dispatch_io(NDhcp4Client *client) {
+        if (!client->current_probe)
                 return -ENOTRECOVERABLE;
 
-        return r;
+        /*
+         * The flags the poller reported were never looked at: the probe reads
+         * its sockets and lets them say what happened.  They are no longer
+         * passed down.
+         */
+        return n_dhcp4_client_probe_dispatch_io(client->current_probe);
 }
 
 /**
@@ -755,24 +704,24 @@
  *         there is more data to dispatch.
  */
 _c_public_ int n_dhcp4_client_dispatch(NDhcp4Client *client) {
-        struct epoll_event events[2];
-        int n, i, r = 0;
+        unsigned int events[2];
+        size_t n = 0, i;
+        int r = 0;
 
-        n = epoll_wait(client->fd_epoll, events, sizeof(events) / sizeof(*events), 0);
-        if (n < 0) {
-                /* Linux never returns EINTR if `timeout == 0'. */
-                return -errno;
-        }
+        r = n_dhcp4_os_poll_wait(client->fd_poll, events,
+                                 sizeof(events) / sizeof(*events), &n);
+        if (r)
+                return r;
 
         client->preempted = false;
 
         for (i = 0; i < n; ++i) {
-                switch (events[i].data.u32) {
+                switch (events[i]) {
                 case N_DHCP4_CLIENT_EPOLL_TIMER:
-                        r = n_dhcp4_client_dispatch_timer(client, events + i);
+                        r = n_dhcp4_client_dispatch_timer(client);
                         break;
                 case N_DHCP4_CLIENT_EPOLL_IO:
-                        r = n_dhcp4_client_dispatch_io(client, events + i);
+                        r = n_dhcp4_client_dispatch_io(client);
                         break;
                 default:
                         c_assert(0);
