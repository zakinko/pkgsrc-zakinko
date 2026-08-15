$NetBSD: patch-src_search.c,v 1.1 2013/04/21 15:40:00 joerg Exp $

Give the functions a declared return type and typed parameters.

Called from another file without a declaration, a function is assumed to
return int.  Where it really returns a pointer or a Lisp_Object that
assumption truncates the value on any machine where the two are not the
same width, and the corruption surfaces far from the call.

--- src/search.c.orig	1995-07-21 06:12:16.000000000 +0000
+++ src/search.c
@@ -115,12 +115,7 @@ matcher_overflow ()
 
 /* Compile a regexp and signal a Lisp error if anything goes wrong.  */
 
-compile_pattern (pattern, bufp, regp, translate, backward)
-     Lisp_Object pattern;
-     struct re_pattern_buffer *bufp;
-     struct re_registers *regp;
-     char *translate;
-     int backward;
+void compile_pattern (Lisp_Object pattern, struct re_pattern_buffer *bufp, struct re_registers *regp, char *translate, int backward)
 {
   CONST char *val;
   Lisp_Object dummy;
