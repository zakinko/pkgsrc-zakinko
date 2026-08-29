$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/xterm.c.orig
+++ src/xterm.c
@@ -403,7 +403,7 @@
 extern int mouse_track_top, mouse_track_left, mouse_track_width;
 
 static
-XTupdate_begin (f)
+int XTupdate_begin (f)
      struct frame *f;
 {	
   int mask;
@@ -458,7 +458,7 @@
 #endif
 
 static
-XTupdate_end (f)
+int XTupdate_end (f)
      struct frame *f;
 {	
   int mask;
@@ -491,7 +491,7 @@
 /* This is called after a redisplay on frame F.  */
 
 static
-XTframe_up_to_date (f)
+int XTframe_up_to_date (f)
      FRAME_PTR f;
 {
   if (mouse_face_deferred_gc || f == mouse_face_mouse_frame)
@@ -506,7 +506,7 @@
    Call this when about to modify line at position VPOS
    and not change whether it is highlighted.  */
 
-XTreassert_line_highlight (new, vpos)
+int XTreassert_line_highlight (new, vpos)
      int new, vpos;
 {
   highlight = new;
@@ -516,7 +516,7 @@
    and change whether it is highlighted.  */
 
 static
-XTchange_line_highlight (new_highlight, vpos, first_unused_hpos)
+int XTchange_line_highlight (new_highlight, vpos, first_unused_hpos)
      int new_highlight, vpos, first_unused_hpos;
 {
   highlight = new_highlight;
@@ -529,7 +529,7 @@
    to Emacs's own window if it is suspended (though that rarely happens).  */
 
 static
-XTset_terminal_modes ()
+int XTset_terminal_modes ()
 {
 }
 
@@ -538,7 +538,7 @@
    requires no action.  */
 
 static
-XTreset_terminal_modes ()
+int XTreset_terminal_modes ()
 {
 /*  XTclear_frame ();  */
 }
@@ -1006,7 +1006,7 @@
    controls the pixel values used for foreground and background.  */
 
 static
-XTwrite_glyphs (start, len)
+int XTwrite_glyphs (start, len)
      register GLYPH *start;
      int len;
 {
@@ -1101,7 +1101,7 @@
 }
 
 static
-XTclear_frame ()
+int XTclear_frame ()
 {
   int mask;
   struct frame *f = updating_frame;
@@ -1340,7 +1340,7 @@
   return x.tv_sec < y.tv_sec;
 }
 
-XTflash (f)
+int XTflash (f)
      struct frame *f;
 {
   BLOCK_INPUT;
@@ -1440,7 +1440,7 @@
    off the feature of using them.  */
 
 static 
-XTinsert_glyphs (start, len)
+int XTinsert_glyphs (start, len)
      register char *start;
      register int len;
 {
@@ -1448,7 +1448,7 @@
 }
 
 static 
-XTdelete_glyphs (n)
+int XTdelete_glyphs (n)
      register int n;
 {
   abort ();
@@ -1460,7 +1460,7 @@
    that is bounded by calls to XTupdate_begin and XTupdate_end.  */
 
 static
-XTset_terminal_window (n)
+int XTset_terminal_window (n)
      register int n;
 {
   if (updating_frame == 0)
@@ -1613,7 +1613,7 @@
 /* Perform an insert-lines or delete-lines operation,
    inserting N lines or deleting -N lines at vertical position VPOS.  */
 
-XTins_del_lines (vpos, n)
+int XTins_del_lines (vpos, n)
      int vpos, n;
 {
   if (updating_frame == 0)
@@ -2337,6 +2337,7 @@
 static void
 note_mouse_highlight (f, x, y)
      FRAME_PTR f;
+     int x, y;
 {
   int row, column, portion;
   XRectangle new_glyph;
@@ -3465,7 +3466,7 @@
    Clear out the scroll bars, and ask for expose events, so we can
    redraw them.  */
 
-x_scroll_bar_clear (f)
+int x_scroll_bar_clear (f)
      FRAME_PTR f;
 {
   Lisp_Object bar;
@@ -5006,7 +5007,7 @@
     XFlushQueue ();
 }
 
-x_display_cursor (f, on)
+int x_display_cursor (f, on)
      struct frame *f;
      int on;
 {
@@ -5028,7 +5029,7 @@
 /* Refresh bitmap kitchen sink icon for frame F
    when we get an expose event for it. */
 
-refreshicon (f)
+int refreshicon (f)
      struct frame *f;
 {
 #ifdef HAVE_X11
@@ -5733,7 +5734,7 @@
 }
 #endif /* ! defined (HAVE_X11) */
 
-x_calc_absolute_position (f)
+int x_calc_absolute_position (f)
      struct frame *f;
 {
 #ifdef HAVE_X11
@@ -5797,7 +5798,7 @@
    x_make_frame_visible (in that case, XOFF and YOFF are the current
    position values).  */
 
-x_set_offset (f, xoff, yoff, change_gravity)
+int x_set_offset (f, xoff, yoff, change_gravity)
      struct frame *f;
      register int xoff, yoff;
      int change_gravity;
@@ -5833,7 +5834,7 @@
    for this size change and subsequent size changes.
    Otherwise we leave the window gravity unchanged.  */
 
-x_set_window_size (f, change_gravity, cols, rows)
+int x_set_window_size (f, change_gravity, cols, rows)
      struct frame *f;
      int change_gravity;
      int cols, rows;
@@ -5958,7 +5959,7 @@
 }
 
 #ifdef HAVE_X11
-x_focus_on_frame (f)
+int x_focus_on_frame (f)
      struct frame *f;
 {
 #if 0  /* This proves to be unpleasant.  */
@@ -5973,7 +5974,7 @@
 #endif /* ! 0 */
 }
 
-x_unfocus_frame (f)
+int x_unfocus_frame (f)
      struct frame *f;
 {
 #if 0
@@ -5988,7 +5989,7 @@
 
 /* Raise frame F.  */
 
-x_raise_frame (f)
+int x_raise_frame (f)
      struct frame *f;
 {
   if (f->async_visible)
@@ -6006,7 +6007,7 @@
 
 /* Lower frame F.  */
 
-x_lower_frame (f)
+int x_lower_frame (f)
      struct frame *f;
 {
   if (f->async_visible)
@@ -6037,7 +6038,7 @@
 /* Change from withdrawn state to mapped state,
    or deiconify. */
 
-x_make_frame_visible (f)
+int x_make_frame_visible (f)
      struct frame *f;
 {
   int mask;
@@ -6112,7 +6113,7 @@
 
 /* Change from mapped state to withdrawn state. */
 
-x_make_frame_invisible (f)
+int x_make_frame_invisible (f)
      struct frame *f;
 {
   int mask;
@@ -6308,7 +6309,7 @@
 
 /* Destroy the X window of frame F.  */
 
-x_destroy_window (f)
+int x_destroy_window (f)
      struct frame *f;
 {
   BLOCK_INPUT;
@@ -6425,7 +6426,7 @@
    If USER_POSITION is nonzero, we set the USPosition
    flag (this is useful when FLAGS is 0).  */
 
-x_wm_set_size_hint (f, flags, user_position)
+int x_wm_set_size_hint (f, flags, user_position)
      struct frame *f;
      long flags;
      int user_position;
@@ -6542,7 +6543,7 @@
 }
 
 /* Used for IconicState or NormalState */
-x_wm_set_window_state (f, state)
+int x_wm_set_window_state (f, state)
      struct frame *f;
      int state;
 {
@@ -6561,7 +6562,7 @@
 #endif /* not USE_X_TOOLKIT */
 }
 
-x_wm_set_icon_pixmap (f, icon_pixmap)
+int x_wm_set_icon_pixmap (f, icon_pixmap)
      struct frame *f;
      Pixmap icon_pixmap;
 {
@@ -6582,7 +6583,7 @@
   XSetWMHints (x_current_display, window, &f->display.x->wm_hints);
 }
 
-x_wm_set_icon_position (f, icon_x, icon_y)
+int x_wm_set_icon_position (f, icon_x, icon_y)
      struct frame *f;
      int icon_x, icon_y;
 {
