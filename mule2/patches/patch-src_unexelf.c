$NetBSD$

Declare open again after the MCPATH block takes the macro away.

config.h pulls in mcpath.h, which defines open as mc_open.  <fcntl.h> is
read after that, so what it declared was mc_open.  This file then undoes
the rename to reach the real system call, and from there on open has no
declaration at all.

--- src/unexelf.c.orig
+++ src/unexelf.c
@@ -458,6 +458,11 @@
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
