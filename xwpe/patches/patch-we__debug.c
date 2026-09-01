$NetBSD$

X11 without Xft does not compile.  WeXterm.h declares backbuf inside
#ifdef HAVE_XFT, but this Expose branch reaches for it unguarded, and
configure calls Xft optional:

  we_debug.c:1269:41: error: 'WpeXStruct' has no member named 'backbuf'

we_xterm.c already has the shape for this at its own Expose case: copy
from the back buffer when there is one, else repaint the area.

--- we_debug.c.orig
+++ we_debug.c
@@ -1266,10 +1266,21 @@
    }
    else if (_ev.type == Expose)
    {
-    XCopyArea(WpeXInfo.display, WpeXInfo.backbuf, WpeXInfo.window,
-      WpeXInfo.gc, _ev.xexpose.x, _ev.xexpose.y,
-      _ev.xexpose.width, _ev.xexpose.height,
-      _ev.xexpose.x, _ev.xexpose.y);
+#ifdef HAVE_XFT
+    if (WpeXInfo.xftfont)
+     XCopyArea(WpeXInfo.display, WpeXInfo.backbuf, WpeXInfo.window,
+       WpeXInfo.gc, _ev.xexpose.x, _ev.xexpose.y,
+       _ev.xexpose.width, _ev.xexpose.height,
+       _ev.xexpose.x, _ev.xexpose.y);
+    else
+#endif
+    {
+     e_refresh_area(_ev.xexpose.x / WpeXInfo.font_width,
+                    _ev.xexpose.y / WpeXInfo.font_height,
+                    _ev.xexpose.width / WpeXInfo.font_width + 2,
+                    _ev.xexpose.height / WpeXInfo.font_height + 2);
+     e_refresh();
+    }
    }
   }
  }
