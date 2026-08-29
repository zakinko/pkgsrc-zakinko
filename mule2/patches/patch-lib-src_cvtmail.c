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

--- lib-src/cvtmail.c.orig
+++ lib-src/cvtmail.c
@@ -34,13 +34,20 @@
 
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
 
-main (argc, argv)
+int main (argc, argv)
      int argc;
      char *argv[];
 {
@@ -103,7 +110,7 @@
   return 0;
 }
 
-skip_to_lf (stream)
+int skip_to_lf (stream)
      FILE *stream;
 {
   register int c;
@@ -134,14 +141,14 @@
 
 /* Print error message and exit.  */
 
-fatal (s1, s2)
+int fatal (s1, s2)
      char *s1, *s2;
 {
   error (s1, s2);
   exit (1);
 }
 
-error (s1, s2)
+int error (s1, s2)
      char *s1, *s2;
 {
   fprintf (stderr, "cvtmail: ");
