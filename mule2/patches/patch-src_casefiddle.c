$NetBSD: patch-src_casefiddle.c,v 1.1 2013/04/21 15:39:59 joerg Exp $

Give the functions a declared return type and typed parameters.

Called from another file without a declaration, a function is assumed to
return int.  Where it really returns a pointer or a Lisp_Object that
assumption truncates the value on any machine where the two are not the
same width, and the corruption surfaces far from the call.

--- src/casefiddle.c.orig	1994-05-04 02:30:58.000000000 +0000
+++ src/casefiddle.c
@@ -104,9 +104,7 @@ The argument object is not altered.")
 /* flag is CASE_UP, CASE_DOWN or CASE_CAPITALIZE or CASE_CAPITALIZE_UP.
    b and e specify range of buffer to operate on. */
 
-casify_region (flag, b, e)
-     enum case_action flag;
-     Lisp_Object b, e;
+static void casify_region (enum case_action flag, Lisp_Object b, Lisp_Object e)
 {
   register int i;
   register int c;
