$NetBSD$

Declare what this program calls, so nothing is reached through an implicit
declaration -- the form C99 removed and clang 16 and gcc 14 reject.  The
standard functions come through their headers, with the file's own
hand-written declarations of them removed where they disagreed; the tree's
own come through the type their definition carries.

--- lib-src/test-distrib.c.orig
+++ lib-src/test-distrib.c
@@ -1,5 +1,13 @@
 #include <stdio.h>
 
+/* Declare what this program calls: the standard functions through their
+   headers, the tree's own through the type their definition carries.
+   Reaching either through an implicit declaration is what C99 removed. */
+#include <fcntl.h>
+#include <stdlib.h>
+#include <string.h>
+#include <unistd.h>
+
 /* Break string in two parts to avoid buggy C compilers that ignore characters
    after nulls in strings.  */
 
