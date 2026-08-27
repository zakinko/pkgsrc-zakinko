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

--- src/s/freebsd.h.orig	1994-11-04 11:11:17.000000000 +0000
+++ src/s/freebsd.h
@@ -81,6 +81,8 @@
 #define BSD 199103
 #elif __FreeBSD__ == 2
 #define BSD 199306
+#elif __FreeBSD__ >= 3
+#define BSD 199506
 #endif
 
 #define WAITTYPE int
