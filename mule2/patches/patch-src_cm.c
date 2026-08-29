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

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

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
@@ -38,7 +41,7 @@
 int cost;		/* sums up costs */
 
 /* ARGSUSED */
-evalcost (c)
+int evalcost (c)
      char c;
 {
   cost++;
@@ -108,7 +111,7 @@
  * out of <sgtty.h>.)
  */
 
-cmcostinit ()
+int cmcostinit ()
 {
     char *p;
 
@@ -148,7 +151,8 @@
  */
 
 static
-calccost (srcy, srcx, dsty, dstx, doit)
+int calccost (srcy, srcx, dsty, dstx, doit)
+     int doit, dstx, dsty, srcx, srcy;
 {
     register int    deltay,
                     deltax,
@@ -282,7 +286,7 @@
 #define	USELL	2
 #define	USECR	3
 
-cmgoto (row, col)
+void cmgoto (int row, int col)
 {
     int     homecost,
             crcost,
@@ -384,7 +388,7 @@
    Used before copying into it the info on the actual terminal.
  */
 
-Wcm_clear ()
+int Wcm_clear ()
 {
   bzero (&Wcm, sizeof Wcm);
   UP = 0;
@@ -398,7 +402,7 @@
  * Return -2 if size not specified.
  */
 
-Wcm_init ()
+int Wcm_init ()
 {
 #if 0
   if (Wcm.cm_abs && !Wcm.cm_ds)
