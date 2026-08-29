$NetBSD: patch-aq,v 1.1 2007/06/11 13:38:37 markd Exp $

Same as patch-aj: drop the hand-written "extern int errno".  errno is a macro
over a per-thread location on any modern system, and the declaration hides it.

--- src/fileio.c.orig	2005-12-29 13:30:15.000000000 +0000
+++ src/fileio.c
@@ -64,12 +64,6 @@ Boston, MA 02111-1307, USA.  */
 
 #include <errno.h>
 
-#ifndef vax11c
-#ifndef USE_CRT_DLL
-extern int errno;
-#endif
-#endif
-
 #ifdef APOLLO
 #include <sys/time.h>
 #endif
