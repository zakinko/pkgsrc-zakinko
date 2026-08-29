$NetBSD$

Declare the functions of this tree that charset.h itself reaches for.

lib-src builds some of ../src straight from source, without lisp.h, so the
declarations that lisp.h carries are not in scope there.  mchar_to_string is
used by a macro in this very header, and search_cmpchar is used by
charset.c.  Both are defined returning int.

--- src/charset.h.orig
+++ src/charset.h
@@ -40,6 +40,12 @@
 #ifndef _CHARSET_H
 #define _CHARSET_H
 
+/* lib-src の m2ps は ../src/charset.c をそのまま読んで組む。あちらは
+   lisp.h を通らないので、この木の中の関数はここで宣言しておかないと
+   暗黙宣言になる。どちらも定義側が int を返す。  */
+extern int mchar_to_string ();
+extern int search_cmpchar ();
+
 /* Definition of leading chars. */
 /** The followings are for 1-byte characters. **/
 #define LCASCII 0x00		/* Omitted in a buffer */
