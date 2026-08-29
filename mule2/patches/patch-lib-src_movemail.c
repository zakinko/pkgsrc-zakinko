$NetBSD$

Declare what this program calls, so nothing is reached through an implicit
declaration -- the form C99 removed and clang 16 and gcc 14 reject.  The
standard functions come through their headers, with the file's own
hand-written declarations of them removed where they disagreed; the tree's
own come through the type their definition carries.

--- lib-src/movemail.c.orig
+++ lib-src/movemail.c
@@ -59,6 +59,14 @@
 #include <string.h>
 #include <../src/syswait.h>
 
+/* Declare what this program calls: the standard functions through their
+   headers, the tree's own through the type their definition carries.
+   Reaching either through an implicit declaration is what C99 removed. */
+extern int error ();
+extern int fatal ();
+extern int pfatal_and_delete ();
+extern int pfatal_with_name ();
+
 #ifdef MSDOS
 #undef access
 #endif /* MSDOS */
