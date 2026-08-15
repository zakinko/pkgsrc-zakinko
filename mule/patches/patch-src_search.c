$NetBSD$

Give compile_pattern a declared return type and typed parameters.

Give the same to skip_chars.  The definition that is actually built --
EMACS18_SKIP_CHARS is defined a few lines above it -- has no return type at
all, so it returns int, while its body returns make_number (...), a
Lisp_Object.  On LP64 that loses the top half at the return itself, before
any caller is involved.  Declaring it without fixing this would only move
the mismatch: src/lisp.h says Lisp_Object, the definition would still say
int, and the two would disagree by four bytes on amd64.

--- src/search.c.orig	1995-07-21 06:12:16.000000000 +0000
+++ src/search.c
@@ -115,12 +115,7 @@
 
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
@@ -617,6 +612,7 @@
 /* 92.11.14 by enami */
 /* The way of handling mc is changed. */
 /* Now, don't to use search_buffer not to modify match-data */
+Lisp_Object
 skip_chars (forwardp, string, lim)
      int forwardp;
      Lisp_Object string, lim;
