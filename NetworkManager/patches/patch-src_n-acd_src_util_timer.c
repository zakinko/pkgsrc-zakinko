$NetBSD$

Get the timer descriptor from the OS rather than from timerfd.

timer.c wants one descriptor that becomes readable when a deadline passes, and
on Linux timerfd is exactly that.  The BSDs have no timerfd, but a kqueue
descriptor is itself pollable, so a kqueue holding a single EVFILT_TIMER
behaves the same way: registering it in the outer kqueue with EVFILT_READ makes
it readable when its timer fires.

That is why this file keeps its shape - Timer still holds one fd, still arms it
with an absolute deadline, and the poller still waits on it.  Only the three
calls that were timerfd-specific move behind n-acd-os.h.

timer_read() now distinguishes "fired" from "nothing pending" through the
seam's return value instead of through EAGAIN, because the two platforms report
an idle timer differently.

--- src/n-acd/src/util/timer.c.orig
+++ src/n-acd/src/util/timer.c
@@ -7,24 +7,26 @@
 #include <c-stdaux.h>
 #include <errno.h>
 #include <stdlib.h>
-#include <sys/timerfd.h>
 #include <time.h>
+#include "n-acd-os.h"
 #include "timer.h"
 
 int timer_init(Timer *timer) {
-        clockid_t clock = CLOCK_BOOTTIME;
-        int r;
+        int clock, fd, r;
 
-        r = timerfd_create(clock, TFD_CLOEXEC | TFD_NONBLOCK);
-        if (r < 0 && errno == EINVAL) {
-                clock = CLOCK_MONOTONIC;
-                r = timerfd_create(clock, TFD_CLOEXEC | TFD_NONBLOCK);
-        }
-        if (r < 0)
-                return -errno;
+        /*
+         * The descriptor and the clock behind it are the OS's to choose: a
+         * timerfd on CLOCK_BOOTTIME where that exists, a timer-only kqueue on
+         * CLOCK_MONOTONIC on the BSDs.  Either way what comes back is one
+         * descriptor that becomes readable when the deadline passes, which is
+         * all the rest of this file needs it to be.
+         */
+        r = n_acd_os_timer_new(&fd, &clock);
+        if (r)
+                return r;
 
         *timer = (Timer)TIMER_NULL(*timer);
-        timer->fd = r;
+        timer->fd = fd;
         timer->clock = clock;
 
         return 0;
@@ -65,15 +67,7 @@
         time = timeout ? timeout->timeout : 0;
 
         if (time != timer->scheduled_timeout) {
-                r = timerfd_settime(timer->fd,
-                                    TFD_TIMER_ABSTIME,
-                                    &(struct itimerspec){
-                                            .it_value = {
-                                                    .tv_sec = time / UINT64_C(1000000000),
-                                                    .tv_nsec = time % UINT64_C(1000000000),
-                                            },
-                                    },
-                                    NULL);
+                r = n_acd_os_timer_set(timer->fd, timer->clock, time);
                 c_assert(r >= 0);
 
                 timer->scheduled_timeout = time;
@@ -81,32 +75,22 @@
 }
 
 int timer_read(Timer *timer) {
-        uint64_t v;
         int r;
 
-        r = read(timer->fd, &v, sizeof(v));
+        r = n_acd_os_timer_read(timer->fd);
         if (r < 0) {
-                if (errno == EAGAIN) {
-                        /*
-                         * No more pending events.
-                         */
-                        return 0;
-                } else {
-                        /*
-                         * Something failed. We use CLOCK_BOOTTIME/MONOTONIC,
-                         * so ECANCELED cannot happen. Hence, there is no
-                         * error that we could gracefully handle. Fail hard
-                         * and let the caller deal with it.
-                         */
-                        return -errno;
-                }
-        } else if (r != sizeof(v) || v == 0) {
                 /*
-                 * Kernel guarantees 8-byte reads, and only to return
-                 * data if at least one timer triggered; fail hard if
-                 * it suddenly starts doing weird shit.
+                 * Something failed. We use CLOCK_BOOTTIME/MONOTONIC, so
+                 * ECANCELED cannot happen. Hence, there is no error that we
+                 * could gracefully handle. Fail hard and let the caller deal
+                 * with it.
                  */
-                return -EIO;
+                return r;
+        } else if (!r) {
+                /*
+                 * No more pending events.
+                 */
+                return 0;
         }
 
         return TIMER_E_TRIGGERED;
