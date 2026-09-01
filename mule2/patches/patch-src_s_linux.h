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

Keep the added headers out of the Makefile-generating pass.

config.h is read twice: once by the compiler, and once by the cpp run that
turns Makefile.in into Makefile.  The second one is traditional cpp and
cannot read a modern glibc header at all, so the includes have to sit
inside #ifndef NOT_C_CODE, the way s/irix4-0.h does it.

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
@@ -138,14 +142,23 @@
  to names for our own functions in sysdep.c that do the system call
  with retries. */
 
-#define read sys_read
-#define write sys_write
-#define open sys_open
-#define close sys_close
-
-#define INTERRUPTIBLE_OPEN
-#define INTERRUPTIBLE_CLOSE
-#define INTERRUPTIBLE_IO
+/* 1995 年の Linux は signal を捕まえると system call が EINTR で戻ったので、
+   sysdep.c の再試行つきの関数に名前を掏り替えていた。いまの glibc の signal
+   は SA_RESTART つきで、read も write も自分で再開する。掏り替えは要らない。
+
+   要らないだけでなく害がある。差し替えたままヘッダを読むと <fcntl.h> が
+   宣言するのは sys_open になり、sysdep.c と繋がらない lib-src では呼ぶ側に
+   宣言も実体も無くなる。 */
+
+#ifndef NOT_C_CODE
+/* glibc は bcopy, bzero, bcmp を <strings.h> でしか宣言しない。config.h は
+   BSTRING を立てて「在る」と言うので、宣言の方をここで配る。str 系も同じで、
+   1995 年の source は宣言なしで呼ぶ。Makefile を作る cpp の段は traditional
+   なので、いまの glibc のヘッダを読めない。だから NOT_C_CODE の外に置く。 */
+#include <string.h>
+#include <strings.h>
+#include <stdlib.h>
+#endif /* not NOT_C_CODE */
 
 /* If you mount the proc file system somewhere other than /proc
    you will have to uncomment the following and make the proper
@@ -162,14 +175,19 @@
 #define GNU_LIBRARY_PENDING_OUTPUT_COUNT(FILE) \
   ((FILE)->_IO_write_ptr - (FILE)->_IO_write_base)
 #else /* !_IO_STDIO_H */
-/* old C++ iostream names */
+/* いまの glibc は _IO_STDIO_H を定義しないが、FILE の中身は _IO_write_ptr の
+   ままで、_pptr という名前は 1990 年代の libg++ のもの。同じ式を使う。 */
 #define GNU_LIBRARY_PENDING_OUTPUT_COUNT(FILE) \
-  ((FILE)->_pptr - (FILE)->_pbase)
+  ((FILE)->_IO_write_ptr - (FILE)->_IO_write_base)
 #endif /* !_IO_STDIO_H */
 #endif /* emacs */
 
 /* Linux has crt0.o in a non-standard place */
-#define START_FILES pre-crt0.o /usr/lib/crt0.o
+/* crt0.o という名前は a.out の頃のもので、いまの glibc には無い (crt1.o と
+   crti.o と gcc の crtbegin.o に分かれている)。link は cc に任せていて、
+   cc が正しい順で並べるので、こちらから名指しする必要はない。unexec が
+   data の始まりを知るための pre-crt0.o だけ残す。 */
+#define START_FILES pre-crt0.o
 
 /* As of version 1.1.51, Linux does not actually implement SIGIO.  */
 /* Here we assume that signal.h is already included.  */
@@ -221,16 +239,28 @@
 
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
 
+/* いまの Linux は ELF で、a.out の頃の dump は使えない。s/netbsd.h が
+   同じ形で ELF の側を選んでいるので、それに倣う。HAVE_TEXT_START は
+   start_of_text を作らせないためのもので、あれは crt0.o の _start を
+   参照する。ELF の unexelf.c はそれを要らない。 */
+#ifdef __ELF__
+
+#define HAVE_TEXT_START
+#define UNEXEC unexelf.o
+#define ORDINARY_LINK
+
+#else /* not __ELF__ */
+
 #ifdef LINUX_QMAGIC
 
 #define HAVE_TEXT_START
@@ -246,6 +276,8 @@
 
 #endif /* not LINUX_QMAGIC */
 
+#endif /* not __ELF__ */
+
 #if 0
 /* In 19.23 and 19.24, configure sometimes fails to define these.
    It has to do with the fact that configure uses CFLAGS when linking
