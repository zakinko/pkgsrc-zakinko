$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/casetab.c.orig
+++ src/casetab.c
@@ -207,7 +207,7 @@
     }
 }
 
-init_casetab_once ()
+int init_casetab_once ()
 {
   register int i;
   Lisp_Object tem;
@@ -232,7 +232,7 @@
 	    : i));
 }
 
-syms_of_casetab ()
+int syms_of_casetab ()
 {
   Qcase_table_p = intern ("case-table-p");
   staticpro (&Qcase_table_p);
