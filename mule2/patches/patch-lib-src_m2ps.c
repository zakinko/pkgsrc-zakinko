$NetBSD$

Declare what this program calls, so nothing is reached through an implicit
declaration -- the form C99 removed and clang 16 and gcc 14 reject.  The
standard functions come through their headers, with the file's own
hand-written declarations of them removed where they disagreed; the tree's
own come through the type their definition carries.

--- lib-src/m2ps.c.orig
+++ lib-src/m2ps.c
@@ -52,6 +52,27 @@
 
 #include <../src/paths.h>
 
+/* Declare what this program calls: the standard functions through their
+   headers, the tree's own through the type their definition carries.
+   Reaching either through an implicit declaration is what C99 removed. */
+#include <stdlib.h>
+extern int bdf_initialize ();
+extern int bdf_load_font ();
+extern int bdf_load_glyph ();
+extern int ccl_driver ();
+extern int control_char ();
+extern int fatal1 ();
+extern int get_line ();
+extern int invalid_char ();
+extern int mulelib_initialize ();
+extern int ps_bop ();
+extern int ps_bot ();
+extern int ps_eop ();
+extern int ps_eot ();
+extern int ps_newfont ();
+extern int ps_newglyph ();
+extern int ps_setfont ();
+
 static char *m2ps_version = "2.2";
 
 #ifndef PSHeader
