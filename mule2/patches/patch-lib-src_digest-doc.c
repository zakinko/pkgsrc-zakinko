$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- lib-src/digest-doc.c.orig
+++ lib-src/digest-doc.c
@@ -6,7 +6,7 @@
    but in texinfo format and sorted by function/variable name.  */
 
 #include <stdio.h>
-main ()
+int main ()
 {
   register int ch;
   register int notfirst = 0;
