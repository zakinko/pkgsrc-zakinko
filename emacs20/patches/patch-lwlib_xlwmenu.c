$NetBSD: patch-ac,v 1.3 2008/01/09 18:27:35 kristerw Exp $

X11 no longer installs <X11/bitmaps/gray>; xbitmaps puts it elsewhere and most
installations do not have it at all.  lwlib ships its own copy, so include that
instead of the system one.

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
