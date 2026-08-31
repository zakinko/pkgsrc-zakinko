$NetBSD$

Ask glibc for the BSD-flavoured declarations the way it wants to be asked.

glibc 2.20 retired _BSD_SOURCE.  Defining it alone no longer turns on
__USE_MISC, so <sys/msg.h> stops defining struct msgbuf and lib-src fails
to build emacsserver with

  error: invalid application of 'sizeof' to incomplete type 'struct msgbuf'

_DEFAULT_SOURCE is the replacement.  _BSD_SOURCE stays beside it for the
libc4 and libc5 systems this file was written for, and having both also
keeps glibc from warning that the old name is deprecated.
Give the Linux configuration what modern glibc no longer volunteers.

Three things this file assumed in 1995 are no longer true.  termio.h is
gone, glibc declares bcopy only in <strings.h>, and nothing declares the
str functions unless the header is read.  The remapping to the sys_*
wrappers makes the last one worse: with it in force the headers declare
sys_open and sys_read, so they have to be read here, after the remap.

--- src/s/linux.h.orig
+++ src/s/linux.h
@@ -72,6 +72,10 @@
 
 #define HAVE_TERMIOS
 
+/* glibc 2.42 で termio.h が消えた。systty.h は termios が在れば
+   termio も在ると思って読みに行くので、要らないと言っておく。 */
+#define NO_TERMIO
+
 /*
  *	Define HAVE_TIMEVAL if the system supports the BSD style clock values.
  *	Look in <sys/time.h> for a timeval structure.
@@ -143,6 +147,20 @@
 #define open sys_open
 #define close sys_close
 
+/* 差し替えた直後にヘッダを読ませる。こうすると <fcntl.h> と
+   <unistd.h> が宣言するのは sys_open や sys_read になり、sysdep.c
+   が用意する実体と名前が揃う。読ませないと、呼ぶ側には宣言の無い
+   sys_open だけが残る。
+
+   string と strings と stdlib もここで配る。config.h は BSTRING を
+   立てて bcopy が在ると言うが、glibc はそれを <strings.h> でしか
+   宣言しない。1995 年の source は str 系を宣言なしで呼ぶ。 */
+#include <string.h>
+#include <strings.h>
+#include <stdlib.h>
+#include <unistd.h>
+#include <fcntl.h>
+
 #define INTERRUPTIBLE_OPEN
 #define INTERRUPTIBLE_CLOSE
 #define INTERRUPTIBLE_IO
@@ -221,12 +239,12 @@
 
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
