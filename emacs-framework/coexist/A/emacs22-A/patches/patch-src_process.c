$NetBSD$

Same as patch-src_buffer.c: drop the hand-written "extern int errno".  See
that patch for what the declaration expands to once <errno.h> has defined
errno as a macro, and for what was measured.

--- src/process.c.orig	2008-10-10 10:35:49.000000000 +0900
+++ src/process.c
@@ -203,9 +203,6 @@ extern Lisp_Object QCfilter;
 
 extern char *get_operating_system_release ();
 
-#ifndef USE_CRT_DLL
-extern int errno;
-#endif
 #ifdef VMS
 extern char *sys_errlist[];
 #endif
