$NetBSD$

Pass and store pointers of the type the other side declares.

gcc 14 turned a pointer type mismatch into an error, so what used to be a
warning here now stops the build.  Where the declaration was simply wrong
it is corrected; where the system call or the library has moved since 1995
the value is converted at the call.

--- src/termhooks.h.orig
+++ src/termhooks.h
@@ -32,7 +32,7 @@
 
 extern int (*clear_to_end_hook) ();
 extern int (*clear_frame_hook) ();
-extern int (*clear_end_of_line_hook) ();
+extern void (*clear_end_of_line_hook) ();
 
 extern int (*ins_del_lines_hook) ();
 
@@ -43,7 +43,7 @@
 extern int (*write_glyphs_hook) ();
 extern int (*delete_glyphs_hook) ();
 
-extern int (*ring_bell_hook) ();
+extern void (*ring_bell_hook) ();
 
 extern int (*reset_terminal_modes_hook) ();
 extern int (*set_terminal_modes_hook) ();
