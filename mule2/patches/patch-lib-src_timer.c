$NetBSD$

Include the headers that declare what this file calls.

The declarations reached this file through some other header on the systems
it was built on, but not on glibc, where they are missing outright.  gcc 14
made an implicit declaration an error, so the build stops here.

Undo the interruptible-system-call remapping before any header is read.

s/linux.h defines read, write, open and close as the sys_* wrappers that
sysdep.c provides for the Emacs binary.  lib-src does not link against
sysdep.c, and with the macros in force <fcntl.h> declares sys_open rather
than open, so the call site is left with no declaration at all.  On Fedora
44 that is an error and the build stops in movemail.

emacsclient.c and emacsserver.c already undo it at the top; movemail.c and
timer.c never did.  NetBSD does not remap, so nothing changes there.

--- lib-src/timer.c.orig
+++ lib-src/timer.c
@@ -20,6 +20,20 @@
 #include <sys/types.h>  /* time_t */
 
 #include <../src/config.h>
+
+/* s/linux.h は割り込まれ得る system call を、sysdep.c が持つ再試行つきの
+   sys_* に差し替える。あれは Emacs 本体のための仕掛けで、lib-src の道具は
+   sysdep.c と繋がらない。差し替えたままヘッダを読むと <fcntl.h> が宣言する
+   のは open ではなく sys_open になり、呼ぶ側には宣言も実体も無くなる。
+   最初のヘッダより前で戻す。emacsclient.c と emacsserver.c は元から同じ事を
+   している。  */
+#undef read
+#undef write
+#undef open
+#undef close
+
+/* Declare the standard functions this file calls. */
+#include <unistd.h>
 #undef read
 
 #ifdef LINUX
