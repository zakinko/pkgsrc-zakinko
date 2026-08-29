$NetBSD$

Declare what this file calls.  The standard functions come through their
headers; reaching them through an implicit declaration is the form C99
removed and clang 16 and gcc 14 reject.

--- src/mcpath.c.orig
+++ src/mcpath.c
@@ -50,6 +50,9 @@
 #include "charset.h"
 #include "coding.h"
 
+/* Declare the standard functions this file calls. */
+#include <fcntl.h>
+
 Lisp_Object Qpathname_coding_system = 0;
 
 /* this function should be lisp function. */
