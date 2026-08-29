$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/mule.c.orig
+++ src/mule.c
@@ -75,7 +75,7 @@
 }
 
 
-syms_of_mule ()
+int syms_of_mule ()
 {
   defsubr (&Sdefine_word_pattern);
 
