$NetBSD$

Add prototypes, and keep them out of the MULTI_FRAME arm.  A build
without a window system takes the other arm, where the declarations
were invisible; keyboard.c hands init_sys_modes to
record_unwind_protect(), and taking a function address is not
something an implicit declaration can cover, so that build did not
compile at all.

--- src/frame.h.orig	1994-10-21 04:20:17.000000000 +0000
+++ src/frame.h
@@ -285,6 +285,8 @@
 #ifdef MULTI_FRAME
 
 typedef struct frame *FRAME_PTR;
+
+void change_frame_size (FRAME_PTR frame, int newheight, int newwidth, int pretend, int delay);
 
 #define XFRAME(p) ((struct frame *) XPNTR (p))
 #define XSETFRAME(p, v) ((struct frame *) XSETPNTR (p, v))
@@ -427,7 +429,7 @@
 extern Lisp_Object Vdefault_frame_alist;
 
 extern Lisp_Object Vterminal_frame;
-
+
 #else /* not MULTI_FRAME */
 
 /* These definitions are used in a single-frame version of Emacs.  */
@@ -529,6 +531,36 @@
 #define FRAME_MODE_LINE_FACE(f) (FRAME_COMPUTED_FACES(f)[1])
 #endif /* TERMINAL_FACE */
 #endif /* not MULTI_FRAME */
+
+/* These are terminal, display and buffer primitives rather than anything
+   to do with multiple frames, but they used to be declared inside the
+   MULTI_FRAME arm above, where a build without a window system never saw
+   them.  keyboard.c passes init_sys_modes to record_unwind_protect(), and
+   taking a function address is one of the few things an implicit
+   declaration cannot cover, so that build failed to compile outright.
+   FRAME_PTR is defined by both arms, so they sit here safely.  */
+void set_window_width (Lisp_Object window, int width, int nodelete);
+void set_window_height (Lisp_Object window, int height, int nodelete);
+void write_glyphs (GLYPH *string, int len);
+void insert_glyphs (GLYPH *start, int len);
+void clear_frame(void);
+void delete_glyphs(int n);
+void ins_del_lines (int vpos, int n);
+void calculate_costs(FRAME_PTR frame);
+void cursor_to (int row, int col);
+void change_line_highlight (int new_highlight, int vpos, int first_unused_hpos);
+void update_end (FRAME_PTR f);
+void set_terminal_window (int size);
+void reassert_line_highlight(int highlight, int vpos);
+void ring_bell(void);
+void set_terminal_modes(void);
+void reset_terminal_modes(void);
+void x_iconify_frame(struct frame *f);
+void discard_tty_input (void);
+void init_sys_modes(void);
+void reset_sys_modes(void);
+void del_range_1 (int from, int to, int prepare);
+void del_range (int from, int to);
 
 
 /* Device- and MULTI_FRAME-independent scroll bar stuff.  */
