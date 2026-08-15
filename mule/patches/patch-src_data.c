$NetBSD: patch-src_data.c,v 1.1 2013/04/21 15:39:59 joerg Exp $

Give the functions a declared return type and typed parameters.

Called from another file without a declaration, a function is assumed to
return int.  Where it really returns a pointer or a Lisp_Object that
assumption truncates the value on any machine where the two are not the
same width, and the corruption surfaces far from the call.

--- src/data.c.orig	2013-03-01 17:41:37.000000000 +0000
+++ src/data.c
@@ -2369,7 +2369,7 @@ arith_error (signo)
   Fsignal (Qarith_error, Qnil);
 }
 
-init_data ()
+void init_data (void)
 {
   /* Don't do this if just dumping out.
      We don't want to call `signal' in this case
