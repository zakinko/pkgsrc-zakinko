$NetBSD: patch-src_window.c,v 1.1 2013/04/21 15:40:00 joerg Exp $

Give the functions a declared return type and typed parameters.

Called from another file without a declaration, a function is assumed to
return int.  Where it really returns a pointer or a Lisp_Object that
assumption truncates the value on any machine where the two are not the
same width, and the corruption surfaces far from the call.

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

Pass and store pointers of the type the other side declares.

gcc 14 turned a pointer type mismatch into an error, so what used to be a
warning here now stops the build.  Where the declaration was simply wrong
it is corrected; where the system call or the library has moved since 1995
the value is converted at the call.

--- src/window.c.orig
+++ src/window.c
@@ -34,6 +34,8 @@
 #include "disptab.h"
 #include "keyboard.h"
 
+static void change_window_height (int delta, int widthflag);
+
 Lisp_Object Qwindowp, Qwindow_live_p;
 
 Lisp_Object Fnext_window (), Fdelete_window (), Fselect_window ();
@@ -652,7 +654,7 @@
 /* Record info on buffer window w is displaying
    when it is about to cease to display that buffer.  */
 static
-unshow_buffer (w)
+int unshow_buffer (w)
      register struct window *w;
 {
   Lisp_Object buf;
@@ -688,7 +690,7 @@
 
 /* Put replacement into the window structure in place of old. */
 static
-replace_window (old, replacement)
+int replace_window (old, replacement)
      Lisp_Object old, replacement;
 {
   register Lisp_Object tem;
@@ -1583,10 +1585,7 @@
    nodelete nonzero means do not do this.
    (The caller should check later and do so if appropriate)  */
 
-set_window_height (window, height, nodelete)
-     Lisp_Object window;
-     int height;
-     int nodelete;
+void set_window_height (Lisp_Object window, int height, int nodelete)
 {
   register struct window *w = XWINDOW (window);
   register struct window *c;
@@ -1648,10 +1647,7 @@
 
 /* Recursively set width of WINDOW and its inferiors. */
 
-set_window_width (window, width, nodelete)
-     Lisp_Object window;
-     int width;
-     int nodelete;
+void set_window_width (Lisp_Object window, int width, int nodelete)
 {
   register struct window *w = XWINDOW (window);
   register struct window *c;
@@ -2007,7 +2003,7 @@
 }
 
 static
-make_dummy_parent (window)
+int make_dummy_parent (window)
      Lisp_Object window;
 {
   register Lisp_Object old, new;
@@ -2198,16 +2194,14 @@
    also changes the heights of the siblings so as to
    keep everything consistent. */
 
-change_window_height (delta, widthflag)
-     register int delta;
-     int widthflag;
+static void change_window_height (int delta, int widthflag)
 {
   register Lisp_Object parent;
   Lisp_Object window;
   register struct window *p;
   int *sizep;
   int (*sizefun) () = widthflag ? window_width : window_height;
-  register int (*setsizefun) () = (widthflag
+  register void (*setsizefun) () = (widthflag
 				   ? set_window_width
 				   : set_window_height);
 
@@ -3149,7 +3143,7 @@
   return unbind_to (count, val);
 }
 
-init_window_once ()
+int init_window_once ()
 {
 #ifdef MULTI_FRAME
   selected_frame = make_terminal_frame ();
@@ -3195,7 +3189,7 @@
 #endif /* not MULTI_FRAME */
 }
 
-syms_of_window ()
+int syms_of_window ()
 {
   Qwindowp = intern ("windowp");
   staticpro (&Qwindowp);
@@ -3344,7 +3338,7 @@
   defsubr (&Ssave_window_excursion);
 }
 
-keys_of_window ()
+int keys_of_window ()
 {
   initial_define_key (control_x_map, '1', "delete-other-windows");
   initial_define_key (control_x_map, '2', "split-window");
