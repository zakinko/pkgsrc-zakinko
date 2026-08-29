$NetBSD$

Declare what this file calls.  The standard functions come through their
headers; reaching them through an implicit declaration is the form C99
removed and clang 16 and gcc 14 reject.

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/prefix-args.c.orig
+++ src/prefix-args.c
@@ -26,7 +26,10 @@
 
 #include <stdio.h>
 
-main (argc, argv)
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+
+int main (argc, argv)
      int argc;
      char **argv;
 {
