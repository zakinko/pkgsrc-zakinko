$NetBSD: patch-src_cm.c,v 1.1 2013/04/21 15:39:59 joerg Exp $

Give the functions a declared return type and typed parameters.

Called from another file without a declaration, a function is assumed to
return int.  Where it really returns a pointer or a Lisp_Object that
assumption truncates the value on any machine where the two are not the
same width, and the corruption surfaces far from the call.

Declare tputs, which this tree defines in termcap.c returning void.

cm.c does not include lisp.h, where the rest of the tree gets this
declaration.  The return value is ignored at both call sites, so the
declaration is right whether the link picks up termcap.c or the system
library.

--- src/cm.c.orig
+++ src/cm.c
@@ -22,6 +22,9 @@
 #include <config.h>
 #include <stdio.h>
 #include "cm.h"
+
+/* 木が自前で持つ termcap.c の tputs。cm.c は lisp.h を読まない。  */
+extern void tputs ();
 #if defined(WIN32) && defined(USE_FATFS) /* 93.2.25 by M.Higashida */
 #include "termhook.h"
 #else
@@ -282,7 +285,7 @@
 #define	USELL	2
 #define	USECR	3
 
-cmgoto (row, col)
+void cmgoto (int row, int col)
 {
     int     homecost,
             crcost,
