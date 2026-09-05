$NetBSD$

Same as patch-src_buffer.c: drop the hand-written "extern int errno".  See
that patch for what the declaration expands to once <errno.h> has defined
errno as a macro, and for what was measured.

--- src/callproc.c.orig	2008-10-10 10:35:49.000000000 +0900
+++ src/callproc.c
@@ -26,10 +26,6 @@ Boston, MA 02110-1301, USA.  */
 #include <errno.h>
 #include <stdio.h>
 
-#ifndef USE_CRT_DLL
-extern int errno;
-#endif
-
 /* Define SIGCHLD as an alias for SIGCLD.  */
 
 #if !defined (SIGCHLD) && defined (SIGCLD)
