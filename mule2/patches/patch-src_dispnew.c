$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/dispnew.c.orig
+++ src/dispnew.c
@@ -235,7 +235,7 @@
   return Qnil;
 }
 
-redraw_frame (f)
+int redraw_frame (f)
      FRAME_PTR f;
 {
   Lisp_Object frame;
@@ -299,8 +299,8 @@
      int empty;
 {
   register int i;
-  register width = FRAME_WIDTH (frame);
-  register height = FRAME_HEIGHT (frame);
+  register int width = FRAME_WIDTH (frame);
+  register int height = FRAME_HEIGHT (frame);
   register struct frame_glyphs *new
     = (struct frame_glyphs *) xmalloc (sizeof (struct frame_glyphs));
 
@@ -537,14 +537,14 @@
 
 /* cancel_line eliminates any request to display a line at position `vpos' */
 
-cancel_line (vpos, frame)
+int cancel_line (vpos, frame)
      int vpos;
      register FRAME_PTR frame;
 {
   FRAME_DESIRED_GLYPHS (frame)->enable[vpos] = 0;
 }
 
-clear_frame_records (frame)
+int clear_frame_records (frame)
      register FRAME_PTR frame;
 {
   bzero (FRAME_CURRENT_GLYPHS (frame)->enable, FRAME_HEIGHT (frame));
@@ -881,7 +881,7 @@
    into the FRAME_DESIRED_GLYPHS (frame) from the FRAME_PHYS_GLYPHS (frame)
    so that update_frame will not change those columns.  */
 
-preserve_other_columns (w)
+int preserve_other_columns (w)
      struct window *w;
 {
   register int vpos;
@@ -1005,7 +1005,7 @@
    for internal consistency.  We cannot check that they are "right";
    we can only look for something nonsensical.  */
 
-verify_charstarts (w)
+int verify_charstarts (w)
      struct window *w;
 {
   FRAME_PTR f = XFRAME (WINDOW_FRAME (w));
@@ -1061,7 +1061,7 @@
    cancel the columns of that window, so that when the window is
    displayed over again get_display_line will not complain.  */
 
-cancel_my_columns (w)
+int cancel_my_columns (w)
      struct window *w;
 {
   register int vpos;
@@ -1264,7 +1264,7 @@
   register int i;
   int pause;
   int preempt_count = baud_rate / 2400 + 1;
-  extern input_pending;
+  extern int input_pending;
 #ifdef HAVE_X_WINDOWS
   register int downto, leftmost;
 #endif
@@ -1453,7 +1453,7 @@
 
 extern void scrolling_1 ();
 
-scrolling (frame)
+int scrolling (frame)
      FRAME_PTR frame;
 {
   int unchanged_at_top, unchanged_at_bottom;
@@ -2082,7 +2082,7 @@
 
 /* Do any change in frame size that was requested by a signal.  */
 
-do_pending_window_change ()
+int do_pending_window_change ()
 {
   /* If window_change_signal should have run before, run it now.  */
   while (delayed_size_change)
@@ -2239,7 +2239,7 @@
   return Qnil;
 }
 
-bitch_at_user ()
+int bitch_at_user ()
 {
   if (noninteractive)
     putchar (07);
@@ -2552,7 +2552,7 @@
 #endif /* SIGWINCH */
 }
 
-syms_of_display ()
+int syms_of_display ()
 {
 #ifdef MULTI_FRAME
   defsubr (&Sredraw_frame);
