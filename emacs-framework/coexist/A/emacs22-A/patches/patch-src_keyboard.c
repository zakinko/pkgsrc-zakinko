$NetBSD$

Same as patch-src_buffer.c: drop the hand-written "extern int errno".  See
that patch for what the declaration expands to once <errno.h> has defined
errno as a macro, and for what was measured.

--- src/keyboard.c.orig	2008-10-10 10:35:49.000000000 +0900
+++ src/keyboard.c
@@ -83,10 +83,6 @@ Boston, MA 02110-1301, USA.  */
 #include "macterm.h"
 #endif
 
-#ifndef USE_CRT_DLL
-extern int errno;
-#endif
-
 /* Variables for blockinput.h: */
 
 /* Non-zero if interrupt input is blocked right now.  */
