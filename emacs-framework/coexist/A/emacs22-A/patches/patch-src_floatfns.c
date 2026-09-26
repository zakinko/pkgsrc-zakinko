$NetBSD$

Same as patch-src_buffer.c: drop the hand-written "extern int errno".  See
that patch for what the declaration expands to once <errno.h> has defined
errno as a macro, and for what was measured.

In this file the declaration is inside "#ifdef FLOAT_CHECK_ERRNO", so it only
ever appeared on configurations that check errno after a libm call.

--- src/floatfns.c.orig	2008-10-10 10:35:49.000000000 +0900
+++ src/floatfns.c
@@ -108,9 +108,6 @@ extern double logb ();
 #ifdef FLOAT_CHECK_ERRNO
 # include <errno.h>
 
-#ifndef USE_CRT_DLL
-extern int errno;
-#endif
 #endif
 
 /* Avoid traps on VMS from sinh and cosh.
