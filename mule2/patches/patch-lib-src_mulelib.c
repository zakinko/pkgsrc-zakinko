$NetBSD$

Declare what this program calls, so nothing is reached through an implicit
declaration -- the form C99 removed and clang 16 and gcc 14 reject.  The
standard functions come through their headers, with the file's own
hand-written declarations of them removed where they disagreed; the tree's
own come through the type their definition carries.

--- lib-src/mulelib.c.orig
+++ lib-src/mulelib.c
@@ -16,6 +16,13 @@
 
 #include <../src/paths.h>
 
+/* Declare what this program calls: the standard functions through their
+   headers, the tree's own through the type their definition carries.
+   Reaching either through an implicit declaration is what C99 removed. */
+extern int init_charset_once ();
+extern int set_ccl_program ();
+extern int update_mc_table ();
+
 char *mule_library_version = "2.2";
 
 int mule_error;
