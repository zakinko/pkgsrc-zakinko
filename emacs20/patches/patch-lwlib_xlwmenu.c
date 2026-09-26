$NetBSD$

<X11/bitmaps/gray> is not installed by modern X.  emacs ships the same bitmap
as src/bitmaps/gray.xbm, and lwlib is compiled with -I../src

	lwlib/Makefile.in:34  ALL_CFLAGS= ... -I. -I../src -I${srcdir} ...

so the quoted include finds it.

--- lwlib/xlwmenu.c.orig	2008-01-09 19:14:56.000000000 +0100
+++ lwlib/xlwmenu.c	2008-01-09 19:15:25.000000000 +0100
@@ -28,7 +28,7 @@
 #include <X11/ObjectP.h>
 #include <X11/StringDefs.h>
 #include <X11/cursorfont.h>
-#include <X11/bitmaps/gray>
+#include "bitmaps/gray.xbm"
 #include "xlwmenuP.h"
 
 static int pointer_grabbed;
