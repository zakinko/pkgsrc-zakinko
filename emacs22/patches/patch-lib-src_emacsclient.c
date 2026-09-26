$NetBSD$

Same as patch-src_buffer.c: drop the hand-written "extern int errno".  See
that patch for what the declaration expands to once <errno.h> has defined
errno as a macro, and for what was measured.

emacsclient is built and linked on its own, so this is the lib-src half of the
same removal.

--- lib-src/emacsclient.c.orig	2008-10-10 10:35:49.000000000 +0900
+++ lib-src/emacsclient.c
@@ -498,7 +498,6 @@ main (argc, argv)
 #define SEND_BUFFER_SIZE   4096
 
 extern char *strerror ();
-extern int errno;
 
 /* Buffer to accumulate data to send in TCP connections.  */
 char send_buffer[SEND_BUFFER_SIZE + 1];
