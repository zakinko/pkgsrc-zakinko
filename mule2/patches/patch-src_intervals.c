$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/intervals.c.orig
+++ src/intervals.c
@@ -144,7 +144,7 @@
      INTERVAL i0, i1;
 {
   register Lisp_Object i0_cdr, i0_sym, i1_val;
-  register i1_len;
+  register int i1_len;
 
   if (DEFAULT_INTERVAL_P (i0) && DEFAULT_INTERVAL_P (i1))
     return 1;
@@ -639,7 +639,7 @@
      register INTERVAL interval;
 {
   register INTERVAL i;
-  register position_of_previous;
+  register int position_of_previous;
 
   if (NULL_INTERVAL_P (interval))
     return NULL_INTERVAL;
