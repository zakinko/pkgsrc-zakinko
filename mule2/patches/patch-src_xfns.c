$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/xfns.c.orig
+++ src/xfns.c
@@ -480,7 +480,7 @@
 /* Attach the `x-frame-parameter' properties to
    the Lisp symbol names of parameters relevant to X.  */
 
-init_x_parm_symbols ()
+int init_x_parm_symbols ()
 {
   int i;
 
@@ -701,7 +701,7 @@
    and whose values are not correctly recorded in the frame's
    param_alist need to be considered here.  */
 
-x_report_frame_params (f, alistptr)
+int x_report_frame_params (f, alistptr)
      struct frame *f;
      Lisp_Object *alistptr;
 {
@@ -1066,7 +1066,7 @@
    Note that this does not fully take effect if done before
    F has an x-window.  */
 
-x_set_border_pixel (f, pix)
+int x_set_border_pixel (f, pix)
      struct frame *f;
      int pix;
 {
@@ -3319,25 +3319,25 @@
     return Qnil;
 }
 
-x_pixel_width (f)
+int x_pixel_width (f)
      register struct frame *f;
 {
   return PIXEL_WIDTH (f);
 }
 
-x_pixel_height (f)
+int x_pixel_height (f)
      register struct frame *f;
 {
   return PIXEL_HEIGHT (f);
 }
 
-x_char_width (f)
+int x_char_width (f)
      register struct frame *f;
 {
   return FONT_WIDTH (f->display.x->font);
 }
 
-x_char_height (f)
+int x_char_height (f)
      register struct frame *f;
 {
   return f->display.x->line_height;
@@ -4485,7 +4485,7 @@
   UNBLOCK_INPUT;
 }
 
-syms_of_xfns ()
+int syms_of_xfns ()
 {
   /* This is zero if not using X windows.  */
   x_current_display = 0;
