$NetBSD$

Declare what this program calls, so nothing is reached through an implicit
declaration -- the form C99 removed and clang 16 and gcc 14 reject.  The
standard functions come through their headers, with the file's own
hand-written declarations of them removed where they disagreed; the tree's
own come through the type their definition carries.

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- lib-src/hexl.c.orig
+++ lib-src/hexl.c
@@ -1,5 +1,12 @@
 #include <stdio.h>
 #include <ctype.h>
+
+/* Declare what this program calls: the standard functions through their
+   headers, the tree's own through the type their definition carries.
+   Reaching either through an implicit declaration is what C99 removed. */
+#include <stdlib.h>
+#include <string.h>
+extern int usage ();
 #ifdef MSDOS
 #include <fcntl.h>
 #endif
@@ -16,7 +23,7 @@
 int group_by = DEFAULT_GROUPING;
 char *progname;
 
-main (argc, argv)
+int main (argc, argv)
      int argc;
      char *argv[];
 {
@@ -231,7 +238,7 @@
   return 0;
 }
 
-usage ()
+int usage ()
 {
   fprintf (stderr, "usage: %s [-de] [-iso]\n", progname);
   exit (1);
