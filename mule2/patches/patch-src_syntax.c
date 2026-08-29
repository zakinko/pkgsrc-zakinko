$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/syntax.c.orig
+++ src/syntax.c
@@ -410,7 +410,7 @@
 }
 /* end of patch */
 
-modify_syntax_entry(c, tbl, syntax)
+int modify_syntax_entry(c, tbl, syntax)
      register unsigned int c;
      Lisp_Object tbl, syntax;
 {				/* 93.2.12 by K.Handa */
@@ -694,7 +694,7 @@
   insert_string ("\n");
 }
 
-describe_syntax_2 (vector, parent) /* 93.6.7, 94.2.23 by K.Handa */
+int describe_syntax_2 (vector, parent) /* 93.6.7, 94.2.23 by K.Handa */
      Lisp_Object vector;
      unsigned int parent;
 {
@@ -748,7 +748,7 @@
    If that many words cannot be found before the end of the buffer, return 0.
    COUNT negative means scan backward and stop at word beginning.  */
 
-scan_words (from, count)
+int scan_words (from, count)
      register int from, count;
 {
   register int beg = BEGV;
@@ -2038,7 +2038,7 @@
 					Qnil))))))));
 }
 
-init_syntax_once ()
+int init_syntax_once ()
 {
   register int i;
   register struct Lisp_Vector *v;
@@ -2076,7 +2076,7 @@
     XFASTINT (v->contents[".,;:?!#@~^'`"[i]]) = (int) Spunct;
 }
 
-syms_of_syntax ()
+int syms_of_syntax ()
 {
   Qsyntax_table_p = intern ("syntax-table-p");
   staticpro (&Qsyntax_table_p);
