$NetBSD: patch-src_regex19.h,v 1.1 2013/04/21 15:40:00 joerg Exp $

Give the functions a declared return type and typed parameters.

Called from another file without a declaration, a function is assumed to
return int.  Where it really returns a pointer or a Lisp_Object that
assumption truncates the value on any machine where the two are not the
same width, and the corruption surfaces far from the call.

--- src/regex19.h.orig	1994-10-24 07:50:11.000000000 +0000
+++ src/regex19.h
@@ -542,6 +542,8 @@ extern size_t regerror
              size_t errbuf_size));
 extern void regfree _RE_ARGS ((regex_t *preg));
 
+void compile_pattern (Lisp_Object pattern, struct re_pattern_buffer *bufp, struct re_registers *regp, char *translate, int backward);
+
 #endif /* not __REGEXP_LIBRARY_H__ */
 
 /*
