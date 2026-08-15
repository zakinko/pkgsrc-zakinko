$NetBSD: patch-src_keyboard.h,v 1.1 2013/04/21 15:39:59 joerg Exp $

Give the functions a declared return type and typed parameters.

Called from another file without a declaration, a function is assumed to
return int.  Where it really returns a pointer or a Lisp_Object that
assumption truncates the value on any machine where the two are not the
same width, and the corruption surfaces far from the call.

--- src/keyboard.h.orig	1994-08-28 19:59:19.000000000 +0000
+++ src/keyboard.h
@@ -105,3 +105,4 @@ extern Lisp_Object read_char ();
 extern Lisp_Object Vkeyboard_translate_table;
 
 extern Lisp_Object map_prompt ();
+void record_asynch_buffer_change(void);
