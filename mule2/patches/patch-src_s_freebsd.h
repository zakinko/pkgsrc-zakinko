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
@@ -47,8 +47,16 @@
 #ifndef NO_SHARED_LIBS
 #define LD_SWITCH_SYSTEM -e start
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
 #define RUN_TIME_REMAP
 
 #ifndef N_TRELOFF
