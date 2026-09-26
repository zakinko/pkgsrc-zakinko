$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/lread.c.orig
+++ src/lread.c
@@ -1445,7 +1445,7 @@
 isfloat_string (cp)
      register char *cp;
 {
-  register state;
+  register int state;
   
   state = 0;
   if (*cp == '+' || *cp == '-')
@@ -1754,7 +1754,7 @@
     }
 }
 
-mapatoms_1 (sym, function)
+int mapatoms_1 (sym, function)
      Lisp_Object sym, function;
 {
   call1 (function, sym);
@@ -1923,7 +1923,7 @@
 
 #endif /* standalone */
 
-init_lread ()
+int init_lread ()
 {
   char *normal;
 
