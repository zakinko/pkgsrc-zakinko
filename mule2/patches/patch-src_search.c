$NetBSD$

Give compile_pattern a declared return type and typed parameters.

Give the same to skip_chars.  The definition that is actually built --
EMACS18_SKIP_CHARS is defined a few lines above it -- has no return type at
all, so it returns int, while its body returns make_number (...), a
Lisp_Object.  On LP64 that loses the top half at the return itself, before
any caller is involved.  Declaring it without fixing this would only move
the mismatch: src/lisp.h says Lisp_Object, the definition would still say
int, and the two would disagree by four bytes on amd64.

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/search.c.orig
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
@@ -193,7 +188,7 @@
 /* Set a pre-compiled pattern into a pattern buffer */
 /* pattern is a list of strings:
 	compiled_code, fastmap, syntax_fastmap, category_fastmap */
-set_pattern (pattern, bufp, translate)
+int set_pattern (pattern, bufp, translate)
      Lisp_Object pattern;
      struct re_pattern_buffer *bufp;
      char *translate;
@@ -498,7 +493,7 @@
    If ALLOW_QUIT is non-zero, set immediate_quit.  That's good to do
    except when inside redisplay.  */
 
-scan_buffer (target, start, count, shortage, allow_quit)
+int scan_buffer (target, start, count, shortage, allow_quit)
      int *shortage, start;
      register int count, target;
      int allow_quit;
@@ -617,6 +612,7 @@
 /* 92.11.14 by enami */
 /* The way of handling mc is changed. */
 /* Now, don't to use search_buffer not to modify match-data */
+Lisp_Object
 skip_chars (forwardp, string, lim)
      int forwardp;
      Lisp_Object string, lim;
@@ -972,7 +968,7 @@
    or else the position at the beginning of the Nth occurrence
    (if searching backward) or the end (if searching forward).  */
 
-search_buffer (string, pos, lim, n, RE, trt, inverse_trt)
+int search_buffer (string, pos, lim, n, RE, trt, inverse_trt)
      Lisp_Object string;
      int pos;
      int lim;
@@ -1953,7 +1949,7 @@
   return val;
 }
   
-syms_of_search ()
+int syms_of_search ()
 {
   register int i;
 
