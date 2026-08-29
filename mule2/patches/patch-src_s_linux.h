$NetBSD$

Ask glibc for the BSD-flavoured declarations the way it wants to be asked.

glibc 2.20 retired _BSD_SOURCE.  Defining it alone no longer turns on
__USE_MISC, so <sys/msg.h> stops defining struct msgbuf and lib-src fails
to build emacsserver with

  error: invalid application of 'sizeof' to incomplete type 'struct msgbuf'

_DEFAULT_SOURCE is the replacement.  _BSD_SOURCE stays beside it for the
libc4 and libc5 systems this file was written for, and having both also
keeps glibc from warning that the old name is deprecated.
--- src/s/linux.h.orig
+++ src/s/linux.h
@@ -221,12 +221,12 @@
 
 #ifdef TERM
 #define LIBS_MACHINE -lclient
-#define C_SWITCH_SYSTEM -D_BSD_SOURCE -I/usr/src/term
+#define C_SWITCH_SYSTEM -D_BSD_SOURCE -D_DEFAULT_SOURCE -I/usr/src/term
 #else
 /* alane@wozzle.linet.org says that -lipc is not a separate library,
    since libc-4.4.1.  So -lipc was deleted.  */
 #define LIBS_MACHINE
-#define C_SWITCH_SYSTEM -D_BSD_SOURCE
+#define C_SWITCH_SYSTEM -D_BSD_SOURCE -D_DEFAULT_SOURCE
 #endif
 
 #define HAVE_SYSVIPC
