$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- lib-src/wakeup.c.orig
+++ lib-src/wakeup.c
@@ -18,7 +18,7 @@
 
 struct tm *localtime ();
 
-main (argc, argv)
+int main (argc, argv)
      int argc;
      char **argv;
 {
