$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/floatfns.c.orig
+++ src/floatfns.c
@@ -938,7 +938,7 @@
 }
 #endif /* HAVE_MATHERR */
 
-init_floatfns ()
+int init_floatfns ()
 {
 #ifdef FLOAT_CATCH_SIGILL
   signal (SIGILL, float_error);
@@ -953,7 +953,7 @@
 
 #endif /* not LISP_FLOAT_TYPE */
 
-syms_of_floatfns ()
+int syms_of_floatfns ()
 {
 #ifdef LISP_FLOAT_TYPE
   defsubr (&Sacos);
