$NetBSD$

Declare what this file calls.  The standard functions come through their
headers; reaching them through an implicit declaration is the form C99
removed and clang 16 and gcc 14 reject.

--- lwlib/lwlib-utils.c.orig
+++ lwlib/lwlib-utils.c
@@ -22,6 +22,9 @@
 #include <X11/ObjectP.h>
 #include "lwlib-utils.h"
 
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+
 #if __STDC__
 extern void *malloc ();
 #else
