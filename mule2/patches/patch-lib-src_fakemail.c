$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- lib-src/fakemail.c.orig
+++ lib-src/fakemail.c
@@ -23,7 +23,7 @@
 
 #if defined (BSD) && !defined (BSD4_1) && !defined (USE_FAKEMAIL)
 /* This program isnot used in BSD, so just avoid loader complaints.  */
-main ()
+int main ()
 {
 }
 #else /* not BSD 4.2 (or newer) */
