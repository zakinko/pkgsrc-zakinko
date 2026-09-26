$NetBSD$

Same as patch-src_buffer.c: drop the hand-written "extern int errno".  See
that patch for what the declaration expands to once <errno.h> has defined
errno as a macro, and for what was measured.

Here it is a local declaration inside window_change_signal, one line above
"int old_errno = errno;", so the function reads errno through the macro either
way.

--- src/dispnew.c.orig	2008-10-10 10:35:49.000000000 +0900
+++ src/dispnew.c
@@ -6167,9 +6167,6 @@ window_change_signal (signalnum) /* If w
      int signalnum;		/* some compilers complain in signal calls.  */
 {
   int width, height;
-#ifndef USE_CRT_DLL
-  extern int errno;
-#endif
   int old_errno = errno;
 
   signal (SIGWINCH, window_change_signal);
