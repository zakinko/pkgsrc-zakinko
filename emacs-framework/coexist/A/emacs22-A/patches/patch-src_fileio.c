$NetBSD$

Same as patch-src_buffer.c: drop the hand-written "extern int errno".  See
that patch for what the declaration expands to once <errno.h> has defined
errno as a macro, and for what was measured.

Here the declaration also sits inside an #ifndef vax11c, which is the only
thing left in this file that mentions VMS's C compiler.  It goes with it.

--- src/fileio.c.orig	2008-10-10 10:35:49.000000000 +0900
+++ src/fileio.c
@@ -61,12 +61,6 @@ Boston, MA 02110-1301, USA.  */
 
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
