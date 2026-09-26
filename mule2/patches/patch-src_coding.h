$NetBSD$

Declare encode_code and ccl_driver for the same reason as charset.h.

coding.c is one of the files lib-src compiles out of ../src without lisp.h.
Neither definition writes a return type, so both are int.

--- src/coding.h.orig
+++ src/coding.h
@@ -47,6 +47,12 @@
 #ifndef _CODING_H
 #define _CODING_H
 
+/* charset.h と同じ事情。lib-src が ../src/coding.c を直に読むときは
+   lisp.h が無いので、ここで宣言する。どちらも型を書かない定義なので
+   int を返す。  */
+extern int encode_code ();
+extern int ccl_driver ();
+
 /* Coding-systems supported in this version. */
 #define NOCONV 0		/* No conversion */
 #define ITNCODE 1		/* Used for buffer contents. */
