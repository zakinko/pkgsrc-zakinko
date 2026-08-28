$NetBSD$

process.c names one of its enum constants INFINITY, but C99 makes INFINITY a
macro in <math.h> and glibc defines it as (__builtin_inff ()).  Where that
header reaches this translation unit the constant is replaced by an
expression and the enum no longer parses:

	process.c:4525:33: error: expected identifier before '(' token

NetBSD does not pull <math.h> in here, so this builds; Fedora 44 with
gcc 15 does, and stops.

Upstream renamed the constant to FOREVER between 26.3 and 27.1 -- 27.2 and
28.2 have `enum { MINIMUM = -1, TIMEOUT, FOREVER } wait;' where this has
INFINITY.  The same rename is applied here, to all five uses, so that the
two functions read as they do upstream.

--- src/process.c.orig
+++ src/process.c
@@ -5028,7 +5028,7 @@
   Lisp_Object proc;
   struct timespec timeout, end_time, timer_delay;
   struct timespec got_output_end_time = invalid_timespec ();
-  enum { MINIMUM = -1, TIMEOUT, INFINITY } wait;
+  enum { MINIMUM = -1, TIMEOUT, FOREVER } wait;
   int got_some_output = -1;
   uintmax_t prev_wait_proc_nbytes_read = wait_proc ? wait_proc->nbytes_read : 0;
 #if defined HAVE_GETADDRINFO_A || defined HAVE_GNUTLS
@@ -5067,7 +5067,7 @@
       end_time = timespec_add (now, make_timespec (time_limit, nsecs));
     }
   else
-    wait = INFINITY;
+    wait = FOREVER;
 
   while (1)
     {
@@ -7555,7 +7555,7 @@
 {
   register int nfds;
   struct timespec end_time, timeout;
-  enum { MINIMUM = -1, TIMEOUT, INFINITY } wait;
+  enum { MINIMUM = -1, TIMEOUT, FOREVER } wait;
 
   if (TYPE_MAXIMUM (time_t) < time_limit)
     time_limit = TYPE_MAXIMUM (time_t);
@@ -7569,7 +7569,7 @@
                                make_timespec (time_limit, nsecs));
     }
   else
-    wait = INFINITY;
+    wait = FOREVER;
 
   /* Turn off periodic alarms (in case they are in use)
      and then turn off any other atimers,
@@ -7675,7 +7675,7 @@
       /*  If we woke up due to SIGWINCH, actually change size now.  */
       do_pending_window_change (0);
 
-      if (wait < INFINITY && nfds == 0 && ! timeout_reduced_for_timers)
+      if (wait < FOREVER && nfds == 0 && ! timeout_reduced_for_timers)
 	/* We waited the full specified time, so return now.  */
 	break;
 
