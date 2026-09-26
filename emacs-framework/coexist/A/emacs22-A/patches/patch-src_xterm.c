$NetBSD$

Same as patch-src_buffer.c: drop the hand-written "extern int errno".  See
that patch for what the declaration expands to once <errno.h> has defined
errno as a macro, and for what was measured.

This one has no #ifndef USE_CRT_DLL around it; it is a bare "extern int
errno;" among the other extern declarations at the top of the file.

--- src/xterm.c.orig	2008-10-10 10:35:49.000000000 +0900
+++ src/xterm.c
@@ -309,8 +309,6 @@ extern Lisp_Object Vx_no_window_manager;
 
 extern Lisp_Object Qeql;
 
-extern int errno;
-
 /* A mask of extra modifier bits to put into every keyboard char.  */
 
 extern EMACS_INT extra_keyboard_modifiers;
