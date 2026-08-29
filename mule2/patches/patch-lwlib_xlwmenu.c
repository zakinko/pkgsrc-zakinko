$NetBSD$

Declare what this file calls.  The standard functions come through their
headers; reaching them through an implicit declaration is the form C99
removed and clang 16 and gcc 14 reject.

Declare the three X error-catching functions of src/xterm.c.

lwlib is built without lisp.h and without any Emacs header, so these come
in as implicit declarations.  x_had_errors_p returns int; the other two
return void.

--- lwlib/xlwmenu.c.orig
+++ lwlib/xlwmenu.c
@@ -29,6 +29,14 @@
 #include <X11/bitmaps/gray>
 #include "xlwmenuP.h"
 
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+
+/* src/xterm.c の X エラー捕捉。lwlib は lisp.h を読まない。  */
+extern void x_catch_errors ();
+extern int x_had_errors_p ();
+extern void x_uncatch_errors ();
+
 static int pointer_grabbed;
 static XEvent menu_post_event;
 
