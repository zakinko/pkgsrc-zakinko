$NetBSD: patch-src_casefiddle.c,v 1.1 2013/04/21 15:39:59 joerg Exp $

Give the functions a declared return type and typed parameters.

Called from another file without a declaration, a function is assumed to
return int.  Where it really returns a pointer or a Lisp_Object that
assumption truncates the value on any machine where the two are not the
same width, and the corruption surfaces far from the call.

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/casefiddle.c.orig
+++ src/casefiddle.c
@@ -104,9 +104,7 @@
 /* flag is CASE_UP, CASE_DOWN or CASE_CAPITALIZE or CASE_CAPITALIZE_UP.
    b and e specify range of buffer to operate on. */
 
-casify_region (flag, b, e)
-     enum case_action flag;
-     Lisp_Object b, e;
+static void casify_region (enum case_action flag, Lisp_Object b, Lisp_Object e)
 {
   register int i;
   register int c;
@@ -253,7 +251,7 @@
   return Qnil;
 }
 
-syms_of_casefiddle ()
+int syms_of_casefiddle ()
 {
   defsubr (&Supcase);
   defsubr (&Sdowncase);
@@ -266,7 +264,7 @@
   defsubr (&Scapitalize_word);
 }
 
-keys_of_casefiddle ()
+int keys_of_casefiddle ()
 {
   initial_define_key (control_x_map, Ctl('U'), "upcase-region");
   Fput (intern ("upcase-region"), Qdisabled, Qt);
