$NetBSD$

Declare what this file calls.  The standard functions come through their
headers; reaching them through an implicit declaration is the form C99
removed and clang 16 and gcc 14 reject.

Declare lwlib_bcopy, which is defined in lwlib.c without a return type.

--- lwlib/lwlib-utils.c.orig
+++ lwlib/lwlib-utils.c
@@ -22,6 +22,12 @@
 #include <X11/ObjectP.h>
 #include "lwlib-utils.h"
 
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+
+/* lwlib.c の中にある。型を書かない定義なので int を返す。  */
+extern int lwlib_bcopy ();
+
 #if __STDC__
 extern void *malloc ();
 #else
