$NetBSD$

Declare what this program calls, so nothing is reached through an implicit
declaration -- the form C99 removed and clang 16 and gcc 14 reject.  The
standard functions come through their headers, with the file's own
hand-written declarations of them removed where they disagreed; the tree's
own come through the type their definition carries.

--- lib-src/cvtmail.c.orig
+++ lib-src/cvtmail.c
@@ -34,8 +34,15 @@
 
 #include <stdio.h>
 
-char *malloc ();
-char *realloc ();
+/* Declare what this program calls: the standard functions through their
+   headers, the tree's own through the type their definition carries.
+   Reaching either through an implicit declaration is what C99 removed. */
+#include <stdlib.h>
+#include <string.h>
+extern int error ();
+extern int fatal ();
+extern int skip_to_lf ();
+
 char *xmalloc ();
 char *xrealloc ();
 char *getenv ();
