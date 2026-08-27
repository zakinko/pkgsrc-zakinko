$NetBSD: patch-src_cm.c,v 1.1 2013/04/21 15:39:59 joerg Exp $

Give the functions a declared return type and typed parameters.

Called from another file without a declaration, a function is assumed to
return int.  Where it really returns a pointer or a Lisp_Object that
assumption truncates the value on any machine where the two are not the
same width, and the corruption surfaces far from the call.

--- src/cm.c.orig	1994-10-21 04:19:53.000000000 +0000
+++ src/cm.c
@@ -282,7 +282,7 @@ losecursor ()
 #define	USELL	2
 #define	USECR	3
 
-cmgoto (row, col)
+void cmgoto (int row, int col)
 {
     int     homecost,
             crcost,
