$NetBSD$

Declare what this file calls.  The standard functions come through their
headers; reaching them through an implicit declaration is the form C99
removed and clang 16 and gcc 14 reject.

--- lwlib/xlwmenu.c.orig
+++ lwlib/xlwmenu.c
@@ -29,6 +29,9 @@
 #include <X11/bitmaps/gray>
 #include "xlwmenuP.h"
 
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+
 static int pointer_grabbed;
 static XEvent menu_post_event;
 
