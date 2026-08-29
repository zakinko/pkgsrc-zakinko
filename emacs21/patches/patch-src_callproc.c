$NetBSD$

Same as patch-aj: drop the hand-written "extern int errno".  errno is a macro
over a per-thread location on any modern system, and the declaration hides it.

--- src/callproc.c.orig	2005-12-29 13:34:29.000000000 +0000
+++ src/callproc.c
@@ -25,10 +25,6 @@ Boston, MA 02111-1307, USA.  */
 #include <errno.h>
 #include <stdio.h>
 
-#ifndef USE_CRT_DLL
-extern int errno;
-#endif
-
 /* Define SIGCHLD as an alias for SIGCLD.  */
 
 #if !defined (SIGCHLD) && defined (SIGCLD)
