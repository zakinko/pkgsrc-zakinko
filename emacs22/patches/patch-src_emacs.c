$NetBSD$

Same as patch-src_buffer.c: drop the hand-written "extern int errno".  See
that patch for what the declaration expands to once <errno.h> has defined
errno as a macro, and for what was measured.

--- src/emacs.c.orig	2008-10-10 10:35:49.000000000 +0900
+++ src/emacs.c
@@ -809,9 +809,6 @@ main (argc, argv
   char stack_bottom_variable;
   int do_initial_setlocale;
   int skip_args = 0;
-#ifndef USE_CRT_DLL
-  extern int errno;
-#endif
 #ifdef HAVE_SETRLIMIT
   struct rlimit rlim;
 #endif
