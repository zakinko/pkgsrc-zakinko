$NetBSD$

Reach the kernel through n-acd-os.h.

n-acd touches the kernel in a small number of places: it opens a packet socket,
sends an ARP, reads a batch of them, attaches a filter, creates a poller and
waits on it.  Everything else - the state machine, the probe scheduling, the
rbtree of addresses - is portable already.

Those calls move behind n-acd-os.h so that the port is a second file rather
than conditionals threaded through here.  n-acd-os-linux.c keeps the PF_PACKET
and epoll code unchanged; n-acd-os-bsd.c does the same work with /dev/bpf and
kqueue.

Two details are worth noting for anyone reading the diff:

The poller is now created after both descriptors exist, because it wants them
at registration time; it used to be created first, back when adding to an epoll
set could be deferred.  The teardown is therefore guarded on the poller itself
rather than on what would have been registered on it - otherwise a failure part
way through n_acd_new() leaves fd_poll unset while the timer is already open,
and the assertion fires.

n_acd_os_socket_recv() reports each packet's length alongside the packets,
because n_acd_packet_is_valid() checks it.  Returning only a count would drop
that check silently.

--- src/n-acd/src/n-acd.c.orig
+++ src/n-acd/src/n-acd.c
@@ -55,48 +55,40 @@
 #include <errno.h>
 #include <inttypes.h>
 #include <limits.h>
-#include <linux/if_packet.h>
 #include <netinet/if_ether.h>
 #include <netinet/in.h>
 #include <stdlib.h>
 #include <string.h>
-#include <sys/auxv.h>
-#include <sys/epoll.h>
 #include <sys/socket.h>
 #include <sys/types.h>
 #include <unistd.h>
 #include "n-acd.h"
+#include "n-acd-os.h"
 #include "n-acd-private.h"
 
-enum {
-        N_ACD_EPOLL_TIMER,
-        N_ACD_EPOLL_SOCKET,
-};
-
 static int n_acd_get_random(unsigned int *random) {
         uint8_t hash_seed[] = {
                 0x3a, 0x0c, 0xa6, 0xdd, 0x44, 0xef, 0x5f, 0x7a,
                 0x5e, 0xd7, 0x25, 0x37, 0xbf, 0x4e, 0x80, 0xa1,
         };
         CSipHash hash = C_SIPHASH_NULL;
+        uint8_t seed[16];
         struct timespec ts;
-        const uint8_t *p;
         int r;
 
         /*
-         * We need random jitter for all timeouts when handling ARP probes. Use
-         * AT_RANDOM to get a seed for rand_r(3p), if available (should always
-         * be available on linux). See the time-out scheduler for details.
+         * We need random jitter for all timeouts when handling ARP probes. Ask
+         * the OS for a seed for rand_r(3p) - AT_RANDOM on Linux,
+         * arc4random(3) elsewhere. See the time-out scheduler for details.
          * Additionally, we include the current time in the seed. This avoids
          * using the same jitter in case you run multiple ACD engines in the
          * same process. Lastly, the seed is hashed with SipHash24 to avoid
-         * exposing the value of AT_RANDOM on the network.
+         * exposing it on the network.
          */
         c_siphash_init(&hash, hash_seed);
 
-        p = (const uint8_t *)getauxval(AT_RANDOM);
-        if (p)
-                c_siphash_append(&hash, p, 16);
+        n_acd_os_random(seed, sizeof(seed));
+        c_siphash_append(&hash, seed, sizeof(seed));
 
         r = clock_gettime(CLOCK_MONOTONIC, &ts);
         if (r < 0)
@@ -106,47 +98,7 @@
         c_siphash_append(&hash, (const uint8_t *)&ts.tv_nsec, sizeof(ts.tv_nsec));
 
         *random = c_siphash_finalize(&hash);
-        return 0;
-}
-
-static int n_acd_socket_new(int *fdp, int fd_bpf_prog, NAcdConfig *config) {
-        const struct sockaddr_ll address = {
-                .sll_family = AF_PACKET,
-                .sll_protocol = htobe16(ETH_P_ARP),
-                .sll_ifindex = config->ifindex,
-                .sll_halen = ETH_ALEN,
-                .sll_addr = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff },
-        };
-        int r, s = -1;
-
-        s = socket(PF_PACKET, SOCK_DGRAM | SOCK_CLOEXEC | SOCK_NONBLOCK, 0);
-        if (s < 0) {
-                r = -c_errno();
-                goto error;
-        }
-
-        if (fd_bpf_prog >= 0) {
-                r = setsockopt(s, SOL_SOCKET, SO_ATTACH_BPF, &fd_bpf_prog, sizeof(fd_bpf_prog));
-                if (r < 0) {
-                        r = -c_errno();
-                        goto error;
-                }
-        }
-
-        r = bind(s, (struct sockaddr *)&address, sizeof(address));
-        if (r < 0) {
-                r = -c_errno();
-                goto error;
-        }
-
-        *fdp = s;
-        s = -1;
         return 0;
-
-error:
-        if (s >= 0)
-                close(s);
-        return r;
 }
 
 /**
@@ -298,11 +250,9 @@
         if (r)
                 return r;
 
-        if (fd_prog >= 0) {
-                r = setsockopt(acd->fd_socket, SOL_SOCKET, SO_ATTACH_BPF, &fd_prog, sizeof(fd_prog));
-                if (r)
-                        return -c_errno();
-        }
+        r = n_acd_os_socket_attach_bpf(acd->fd_socket, fd_prog);
+        if (r)
+                return r;
 
         if (acd->fd_bpf_map >= 0)
                 close(acd->fd_bpf_map);
@@ -328,7 +278,6 @@
 _c_public_ int n_acd_new(NAcd **acdp, NAcdConfig *config) {
         _c_cleanup_(n_acd_unrefp) NAcd *acd = NULL;
         _c_cleanup_(c_closep) int fd_bpf_prog = -1;
-        struct epoll_event eevent;
         int r;
 
         if (config->ifindex <= 0 ||
@@ -349,10 +298,6 @@
         if (r)
                 return r;
 
-        acd->fd_epoll = epoll_create1(EPOLL_CLOEXEC);
-        if (acd->fd_epoll < 0)
-                return -c_errno();
-
         r = timer_init(&acd->timer);
         if (r < 0)
                 return r;
@@ -367,25 +312,18 @@
         if (r)
                 return r;
 
-        r = n_acd_socket_new(&acd->fd_socket, fd_bpf_prog, config);
+        r = n_acd_os_socket_new(&acd->fd_socket, config->ifindex, fd_bpf_prog);
         if (r)
                 return r;
 
-        eevent = (struct epoll_event){
-                .events = EPOLLIN,
-                .data.u32 = N_ACD_EPOLL_TIMER,
-        };
-        r = epoll_ctl(acd->fd_epoll, EPOLL_CTL_ADD, acd->timer.fd, &eevent);
-        if (r < 0)
-                return -c_errno();
-
-        eevent = (struct epoll_event){
-                .events = EPOLLIN,
-                .data.u32 = N_ACD_EPOLL_SOCKET,
-        };
-        r = epoll_ctl(acd->fd_epoll, EPOLL_CTL_ADD, acd->fd_socket, &eevent);
-        if (r < 0)
-                return -c_errno();
+        /*
+         * The poller is created once both descriptors exist, because it wants
+         * them at registration time.  It used to be created first, back when
+         * this was epoll only and adding could be deferred.
+         */
+        r = n_acd_os_poll_new(&acd->fd_poll, acd->fd_socket, acd->timer.fd);
+        if (r)
+                return r;
 
         *acdp = acd;
         acd = NULL;
@@ -403,9 +341,16 @@
 
         c_assert(c_rbtree_is_empty(&acd->ip_tree));
 
+        /*
+         * The poller is created last, once both descriptors exist, so a
+         * failure earlier in n_acd_new() leaves it unset while the timer is
+         * already open.  Unregistering is therefore conditional on the poller
+         * rather than on what would have been registered on it.
+         */
+        if (acd->fd_poll >= 0)
+                n_acd_os_poll_del(acd->fd_poll, acd->fd_socket, acd->timer.fd);
+
         if (acd->fd_socket >= 0) {
-                c_assert(acd->fd_epoll >= 0);
-                epoll_ctl(acd->fd_epoll, EPOLL_CTL_DEL, acd->fd_socket, NULL);
                 close(acd->fd_socket);
                 acd->fd_socket = -1;
         }
@@ -415,15 +360,12 @@
                 acd->fd_bpf_map = -1;
         }
 
-        if (acd->timer.fd >= 0) {
-                c_assert(acd->fd_epoll >= 0);
-                epoll_ctl(acd->fd_epoll, EPOLL_CTL_DEL, acd->timer.fd, NULL);
+        if (acd->timer.fd >= 0)
                 timer_deinit(&acd->timer);
-        }
 
-        if (acd->fd_epoll >= 0) {
-                close(acd->fd_epoll);
-                acd->fd_epoll = -1;
+        if (acd->fd_poll >= 0) {
+                close(acd->fd_poll);
+                acd->fd_poll = -1;
         }
 
         free(acd);
@@ -476,13 +418,6 @@
 }
 
 int n_acd_send(NAcd *acd, const struct in_addr *tpa, const struct in_addr *spa) {
-        struct sockaddr_ll address = {
-                .sll_family = AF_PACKET,
-                .sll_protocol = htobe16(ETH_P_ARP),
-                .sll_ifindex = acd->ifindex,
-                .sll_halen = ETH_ALEN,
-                .sll_addr = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff },
-        };
         struct ether_arp arp = {
                 .ea_hdr = {
                         .ar_hrd = htobe16(ARPHRD_ETHER),
@@ -492,7 +427,6 @@
                         .ar_op = htobe16(ARPOP_REQUEST),
                 },
         };
-        ssize_t l;
         int r;
 
         memcpy(arp.arp_sha, acd->mac, sizeof(acd->mac));
@@ -501,51 +435,42 @@
         if (spa)
                 memcpy(arp.arp_spa, &spa->s_addr, sizeof(spa->s_addr));
 
-        l = sendto(acd->fd_socket,
-                   &arp,
-                   sizeof(arp),
-                   MSG_NOSIGNAL,
-                   (struct sockaddr *)&address,
-                   sizeof(address));
-        if (l < 0) {
-                if (errno == EAGAIN || errno == ENOBUFS) {
-                        /*
-                         * We never maintain outgoing queues. We rely on the
-                         * network device to do that for us. In case the queues
-                         * are full, or the kernel refuses to queue the packet
-                         * for other reasons, we must tell our caller that the
-                         * packet was dropped.
-                         */
-                        return N_ACD_E_DROPPED;
-                } else if (errno == ENETDOWN || errno == ENXIO) {
-                        /*
-                         * These errors happen if the network device went down
-                         * or was actually removed. We always propagate this as
-                         * event, so the user can react accordingly (similarly
-                         * to the recvmmsg(2) handler). In case the user does
-                         * not immediately react, we also tell our caller that
-                         * the packet was dropped, so we don't erroneously
-                         * treat this as success.
-                         */
+        /*
+         * The two platforms disagree on how a broadcast is addressed - a
+         * sockaddr_ll on Linux, a whole Ethernet header written by hand on the
+         * BSDs - so the destination is the seam's business and only the ARP
+         * payload crosses it.  A short write is the seam's to reject, too.
+         */
+        r = n_acd_os_socket_send(acd->fd_socket, acd->ifindex, acd->mac, &arp);
+        if (r == -EAGAIN || r == -ENOBUFS) {
+                /*
+                 * We never maintain outgoing queues. We rely on the network
+                 * device to do that for us. In case the queues are full, or
+                 * the kernel refuses to queue the packet for other reasons, we
+                 * must tell our caller that the packet was dropped.
+                 */
+                return N_ACD_E_DROPPED;
+        } else if (r == -ENETDOWN || r == -ENXIO) {
+                /*
+                 * These errors happen if the network device went down or was
+                 * actually removed. We always propagate this as event, so the
+                 * user can react accordingly (similarly to the receive
+                 * handler). In case the user does not immediately react, we
+                 * also tell our caller that the packet was dropped, so we
+                 * don't erroneously treat this as success.
+                 */
 
-                        r = n_acd_raise(acd, NULL, N_ACD_EVENT_DOWN);
-                        if (r)
-                                return r;
+                r = n_acd_raise(acd, NULL, N_ACD_EVENT_DOWN);
+                if (r)
+                        return r;
 
-                        return N_ACD_E_DROPPED;
-                }
-
+                return N_ACD_E_DROPPED;
+        } else if (r) {
                 /*
                  * Random network error. We treat this as fatal and propagate
                  * the error, so it is noticed and can be investigated.
                  */
-                return -c_errno();
-        } else if (l != (ssize_t)sizeof(arp)) {
-                /*
-                 * Ugh, the kernel modified the packet. This is unexpected. We
-                 * consider the packet lost.
-                 */
-                return N_ACD_E_DROPPED;
+                return r;
         }
 
         return 0;
@@ -566,10 +491,11 @@
  * it. Whenever the file-descriptor polls readable, n_acd_dispatch() should be
  * called.
  *
- * Currently, the file-descriptor is an epoll-fd.
+ * Currently, the file-descriptor is the poller's: an epoll-fd on Linux, a
+ * kqueue elsewhere.
  */
 _c_public_ void n_acd_get_fd(NAcd *acd, int *fdp) {
-        *fdp = acd->fd_epoll;
+        *fdp = acd->fd_poll;
 }
 
 static int n_acd_handle_timeout(NAcd *acd) {
@@ -702,37 +628,27 @@
         return 0;
 }
 
-static int n_acd_dispatch_timer(NAcd *acd, struct epoll_event *event) {
+static int n_acd_dispatch_timer(NAcd *acd) {
         int r;
 
-        if (event->events & (EPOLLHUP | EPOLLERR)) {
-                /*
-                 * There is no way to handle either gracefully. If we ignored
-                 * them, we would busy-loop, so lets rather forward the error
-                 * to the caller.
-                 */
-                return -EIO;
-        }
+        /*
+         * The poller no longer reports HUP or ERR separately: kqueue folds
+         * them into the read, and both platforms surface a broken timer as a
+         * failure out of timer_read().  That is where it is handled now.
+         */
+        r = timer_read(&acd->timer);
+        if (r <= 0)
+                return r;
 
-        if (event->events & EPOLLIN) {
-                r = timer_read(&acd->timer);
-                if (r <= 0)
-                        return r;
+        c_assert(r == TIMER_E_TRIGGERED);
 
-                c_assert(r == TIMER_E_TRIGGERED);
-
-                /*
-                 * A timer triggered, handle all pending timeouts at a given
-                 * point in time. There can only be a finite number of pending
-                 * timeouts, any new ones will be in the future, so not handled
-                 * now, but guaranteed to wake us up again when they do trigger.
-                 */
-                r = n_acd_handle_timeout(acd);
-                if (r)
-                        return r;
-        }
-
-        return 0;
+        /*
+         * A timer triggered, handle all pending timeouts at a given point in
+         * time. There can only be a finite number of pending timeouts, any new
+         * ones will be in the future, so not handled now, but guaranteed to
+         * wake us up again when they do trigger.
+         */
+        return n_acd_handle_timeout(acd);
 }
 
 static bool n_acd_packet_is_valid(NAcd *acd, void *packet, size_t n_packet) {
@@ -776,65 +692,39 @@
         return true;
 }
 
-static int n_acd_dispatch_socket(NAcd *acd, struct epoll_event *event) {
+static int n_acd_dispatch_socket(NAcd *acd) {
         const size_t n_batch = 8;
-        struct mmsghdr msgs[n_batch];
-        struct iovec iovecs[n_batch];
         struct ether_arp data[n_batch];
-        size_t i;
-        int r, n;
+        size_t lens[n_batch];
+        size_t i, n = 0;
+        int r;
 
-        for (i = 0; i < n_batch; ++i) {
-                iovecs[i].iov_base = data + i;
-                iovecs[i].iov_len = sizeof(data[i]);
-                msgs[i].msg_hdr = (struct msghdr){
-                        .msg_iov = iovecs + i,
-                        .msg_iovlen = 1,
-                };
-        }
-
         /*
-         * We always directly call into recvmmsg(2), regardless which EPOLL*
-         * event is signalled. On sockets, the recv(2)-family of syscalls does
-         * a suitable job of handling all possible scenarios and telling us
-         * about it. Hence, lets take the easy route and always ask the kernel
-         * about the current state.
+         * We always read, regardless of what the poller told us.  Asking the
+         * kernel about the current state handles every scenario the flags
+         * could have described, and it is the same call on both platforms.
          */
-        n = recvmmsg(acd->fd_socket, msgs, n_batch, 0, NULL);
-        if (n < 0) {
-                if (errno == ENETDOWN) {
-                        /*
-                         * We get ENETDOWN if the network-device goes down or
-                         * is removed. This error is temporary and only queued
-                         * once. Subsequent reads will simply return EAGAIN
-                         * until the device is up again and has data queued.
-                         * Usually, the caller should tear down all probes when
-                         * an interface goes down, but we leave it up to the
-                         * caller to decide what to do. We propagate the code
-                         * and continue.
-                         */
-                        return n_acd_raise(acd, NULL, N_ACD_EVENT_DOWN);
-                } else if (errno == EAGAIN) {
-                        /*
-                         * There is no more data queued and we did not get
-                         * preempted. Everything is good to go.
-                         * As a safety-net against busy-looping, we do check
-                         * for HUP/ERR. Neither should be set, since they imply
-                         * error-dequeue behavior on all socket calls. Lets
-                         * fail hard if we trigger it, so we can investigate.
-                         */
-                        if (event->events & (EPOLLHUP | EPOLLERR))
-                                return -EIO;
+        r = n_acd_os_socket_recv(acd->fd_socket, data, lens, n_batch, &n);
+        if (r == -ENETDOWN) {
+                /*
+                 * We get ENETDOWN if the network-device goes down or is
+                 * removed. This error is temporary and only queued once.
+                 * Subsequent reads will simply return nothing until the device
+                 * is up again and has data queued. Usually, the caller should
+                 * tear down all probes when an interface goes down, but we
+                 * leave it up to the caller to decide what to do. We propagate
+                 * the code and continue.
+                 */
+                return n_acd_raise(acd, NULL, N_ACD_EVENT_DOWN);
+        } else if (r) {
+                /*
+                 * Something went wrong. Propagate the error-code, so this can
+                 * be investigated.
+                 */
+                return r;
+        }
 
-                        return 0;
-                } else {
-                        /*
-                         * Something went wrong. Propagate the error-code, so
-                         * this can be investigated.
-                         */
-                        return -c_errno();
-                }
-        } else if (n >= (ssize_t)n_batch) {
+        if (n >= n_batch) {
                 /*
                  * If all buffers were filled with data, we cannot be sure that
                  * there is nothing left to read. But to avoid starvation, we
@@ -847,16 +737,16 @@
                  * On the other hand, there are several conditions where the
                  * kernel might return less batches than requested, but was
                  * still preempted. However, all of those cases require the
-                 * preemption to have triggered a wakeup *after* we entered
-                 * recvmmsg(). Hence, even if we did not recognize the
-                 * preemption, an edge must have triggered and as such we will
-                 * handle the event on the next turn.
+                 * preemption to have triggered a wakeup *after* we entered the
+                 * read. Hence, even if we did not recognize the preemption, an
+                 * edge must have triggered and as such we will handle the
+                 * event on the next turn.
                  */
                 acd->preempted = true;
         }
 
-        for (i = 0; (ssize_t)i < n; ++i) {
-                if (!n_acd_packet_is_valid(acd, data + i, msgs[i].msg_len))
+        for (i = 0; i < n; ++i) {
+                if (!n_acd_packet_is_valid(acd, data + i, lens[i]))
                         continue;
                 /*
                  * Handle the packet. Bail out if something went wrong. Note
@@ -893,24 +783,23 @@
  *         on failure.
  */
 _c_public_ int n_acd_dispatch(NAcd *acd) {
-        struct epoll_event events[2];
-        int n, i, r = 0;
+        unsigned int events[2];
+        size_t i, n = 0;
+        int r = 0;
 
-        n = epoll_wait(acd->fd_epoll, events, sizeof(events) / sizeof(*events), 0);
-        if (n < 0) {
-                /* Linux never returns EINTR if `timeout == 0'. */
-                return -c_errno();
-        }
+        r = n_acd_os_poll_wait(acd->fd_poll, events, sizeof(events) / sizeof(*events), &n);
+        if (r)
+                return r;
 
         acd->preempted = false;
 
         for (i = 0; i < n; ++i) {
-                switch (events[i].data.u32) {
-                case N_ACD_EPOLL_TIMER:
-                        r = n_acd_dispatch_timer(acd, events + i);
+                switch (events[i]) {
+                case N_ACD_OS_EVENT_TIMER:
+                        r = n_acd_dispatch_timer(acd);
                         break;
-                case N_ACD_EPOLL_SOCKET:
-                        r = n_acd_dispatch_socket(acd, events + i);
+                case N_ACD_OS_EVENT_SOCKET:
+                        r = n_acd_dispatch_socket(acd);
                         break;
                 default:
                         c_assert(0);
@@ -941,7 +830,7 @@
  * context.
  *
  * Users must call this function repeatedly until either an error is returned,
- * or the event-pointer is NULL. Wakeups on the epoll-fd are only guaranteed
+ * or the event-pointer is NULL. Wakeups on the poll-fd are only guaranteed
  * for each batch of events. Hence, it is the callers responsibility to drain
  * the event-queue somehow after each call to n_acd_dispatch(). Note that
  * events can only be added by n_acd_dispatch(), hence, you cannot live-lock
