$NetBSD$

Give BSD a value on FreeBSD 3 and newer.

s/bsd4-3.h defines BSD as 43.  This file then undefines it and defines it
again only for __FreeBSD__ 1 and 2, the releases that existed in 1994, so
on anything newer BSD is left undefined and the tree takes its non-BSD
paths throughout.  Two of those stop the build outright.  lib-src/fakemail.c
compiles its whole 1994 body instead of the empty main() that
`#if defined (BSD)' selects, and its parse_header has no return type while
its body ends in a bare `return;'.  src/emacs.c declares `extern sys_nerr;'
with no type at all.  Modern clang rejects both rather than warning.

Emacs 20.1 added the same arm as `#elif __FreeBSD__ == 3' and 21.1 widened
it to `>= 3'; by then the macro had been renamed BSD_SYSTEM.  199506 is the
value upstream uses.

Pick the ELF dumper on FreeBSD too.

s/freebsd.h still names the a.out dumper and /usr/lib/crt0.o, which no
longer exists.  The a.out unexec pulls in start_of_text, which refers to
_start from crt0.o, so the link of temacs fails before anything runs.
s/netbsd.h already has the shape for this; use the same one.

--- src/s/freebsd.h.orig
+++ src/s/freebsd.h
@@ -33,7 +33,10 @@
 
 #define LIBS_DEBUG
 #define LIBS_SYSTEM -lutil
-#define LIBS_TERMCAP -ltermcap
+/* GhostBSD には libtermcap という名前が無い。FreeBSD 系は termcap の
+   API を ncurses が持っているので、そちらを名指しする。FreeBSD 本体でも
+   libtermcap は ncurses への symlink でしかない。 */
+#define LIBS_TERMCAP -lncurses
 #define LIB_GCC -lgcc
 
 /* Reread the time zone on startup. */
@@ -45,11 +48,29 @@
 #undef BSD_PGRPS
 
 #ifndef NO_SHARED_LIBS
+/* -e start は a.out の入口名。ELF では _start で、link を cc に
+   任せるなら指定そのものが要らない。指定すると ld が
+   "cannot find entry symbol start" と言って入口を設定しない。 */
+#ifndef __ELF__
 #define LD_SWITCH_SYSTEM -e start
+#endif
 #define HAVE_TEXT_START		/* No need to define `start_of_text'. */
+/* いまの FreeBSD は ELF で、crt0.o という名前も無い。s/netbsd.h と
+   同じ形で ELF の側を選ぶ。link は cc に任せるので START_FILES を
+   名指しする必要も無い。 */
+#ifdef __ELF__
+#define UNEXEC unexelf.o
+#define ORDINARY_LINK
+#else /* not __ELF__ */
 #define START_FILES pre-crt0.o /usr/lib/crt0.o
 #define UNEXEC unexsunos4.o
+#endif /* not __ELF__ */
+/* run_time_remap は unexsunos4.c にある。ELF では unexelf.o を選ぶので
+   実体が来ず、emacs.c がこれを呼んで link が通らない。s/netbsd.h は
+   同じ定義を a.out の側の枠に入れている。 */
+#ifndef __ELF__
 #define RUN_TIME_REMAP
+#endif
 
 #ifndef N_TRELOFF
 #define N_PAGSIZ(x) __LDPGSZ
@@ -89,3 +110,9 @@
 #include <sys/wait.h>
 #endif
 #define WRETCODE(w) (_W_INT(w) >> 8)
+
+/* いまの FreeBSD の getpgrp は POSIX の形で、引数を取らない。systty.h は
+   GETPGRP_NO_ARG が立っていないと 4.2BSD の getpgrp(pid) を呼ぶ。  */
+#ifndef GETPGRP_NO_ARG
+#define GETPGRP_NO_ARG
+#endif
