$NetBSD: patch-src_insdel.c,v 1.1 2013/04/21 15:39:59 joerg Exp $

Give the functions a declared return type and typed parameters.

Called from another file without a declaration, a function is assumed to
return int.  Where it really returns a pointer or a Lisp_Object that
assumption truncates the value on any machine where the two are not the
same width, and the corruption surfaces far from the call.

--- src/insdel.c.orig	1994-10-24 03:58:26.000000000 +0000
+++ src/insdel.c
@@ -589,17 +589,16 @@ insert_from_string_after_markers (string
 
 /* Delete characters in current buffer
    from FROM up to (but not including) TO.  */
+void del_range_1 (int from, int to, int prepare);
 
-del_range (from, to)
-     register int from, to;
+void del_range (int from, int to)
 {
-  return del_range_1 (from, to, 1);
+  del_range_1 (from, to, 1);
 }
 
 /* Like del_range; PREPARE says whether to call prepare_to_modify_buffer.  */
 
-del_range_1 (from, to, prepare)
-     register int from, to, prepare;
+void del_range_1 (int from, int to, int prepare)
 {
   register int numdel;
 
