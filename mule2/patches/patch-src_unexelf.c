$NetBSD$

Declare open again after the MCPATH block takes the macro away.

config.h pulls in mcpath.h, which defines open as mc_open.  <fcntl.h> is
read after that, so what it declared was mc_open.  This file then undoes
the rename to reach the real system call, and from there on open has no
declaration at all.

Declare fatal, which is a function in emacs.c when this file is built as
part of Emacs.  The macro of the same name a few lines above is only for
the standalone build, so the declaration is inside #ifdef emacs.

--- src/unexelf.c.orig
+++ src/unexelf.c
@@ -439,6 +439,13 @@
 #include <elf.h>
 #endif
 #include <sys/mman.h>
+
+/* emacs の中で組むときの fatal は emacs.c の関数で、上の #ifndef emacs
+   の巨視ではない。unexelf.c は lisp.h を読まないのでここで宣言する。
+   巨視の側に当たらないよう emacs のときだけにする。  */
+#ifdef emacs
+extern int fatal ();
+#endif
 #if defined (__sony_news) && defined (_SYSTYPE_SYSV)
 #include <sys/elf_mips.h>
 #include <sym.h>
@@ -458,6 +465,11 @@
 #ifdef MCPATH			/* hir, 1993.8.4 */
 #undef open
 #undef chmod
+
+/* config.h から入る mcpath.h が open を mc_open に置き換えるので、この
+   上で読んでいる <fcntl.h> は mc_open を宣言していた。ここで名前を戻す
+   と、宣言の無い open が残る。素の system call を宣言し直す。  */
+extern int open ();
 #endif  
 
 #ifndef MAP_FAILED
