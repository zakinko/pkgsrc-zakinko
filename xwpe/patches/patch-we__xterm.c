$NetBSD$

X11 without Xft does not compile.  These three whole-window blits after
a resize read WpeXInfo.backbuf, which WeXterm.h only declares inside
#ifdef HAVE_XFT, while the Expose case a few lines above guards the same
access.  Without a back buffer the repaint that follows
(e_relayout_windows, e_x_repaint_desk) is what draws, so the blit is
simply skipped.

--- we_xterm.c.orig
+++ we_xterm.c
@@ -1087,8 +1087,11 @@
     { int _pw, _ph, _old_scol, _old_slns;
       if (e_x_apply_configure(&report, &_pw, &_ph, &_old_scol, &_old_slns))
       {
-       XCopyArea(WpeXInfo.display, WpeXInfo.backbuf, WpeXInfo.window,
-         WpeXInfo.gc, 0, 0, _pw, _ph, 0, 0);
+#ifdef HAVE_XFT
+       if (WpeXInfo.xftfont)
+        XCopyArea(WpeXInfo.display, WpeXInfo.backbuf, WpeXInfo.window,
+          WpeXInfo.gc, 0, 0, _pw, _ph, 0, 0);
+#endif
        e_relayout_windows(WpeEditor, _old_scol, _old_slns);
        e_x_repaint_desk(WpeEditor->f[WpeEditor->mxedt]);
       }
@@ -1266,8 +1269,11 @@
     { int _i, _pw, _ph, _old_scol, _old_slns;
       if (e_x_apply_configure(&report, &_pw, &_ph, &_old_scol, &_old_slns))
       {
-       XCopyArea(WpeXInfo.display, WpeXInfo.backbuf, WpeXInfo.window,
-         WpeXInfo.gc, 0, 0, _pw, _ph, 0, 0);
+#ifdef HAVE_XFT
+       if (WpeXInfo.xftfont)
+        XCopyArea(WpeXInfo.display, WpeXInfo.backbuf, WpeXInfo.window,
+          WpeXInfo.gc, 0, 0, _pw, _ph, 0, 0);
+#endif
        XFlush(WpeXInfo.display);
 
        /* If the last-view pic is not a live window's, drop it: the grid (and so
@@ -1280,8 +1286,11 @@
          if (!_is_win_pic)
           (*e_u_setlastpic)(NULL);
        }
-       XCopyArea(WpeXInfo.display, WpeXInfo.backbuf, WpeXInfo.window,
-         WpeXInfo.gc, 0, 0, _pw, _ph, 0, 0);
+#ifdef HAVE_XFT
+       if (WpeXInfo.xftfont)
+        XCopyArea(WpeXInfo.display, WpeXInfo.backbuf, WpeXInfo.window,
+          WpeXInfo.gc, 0, 0, _pw, _ph, 0, 0);
+#endif
        e_relayout_windows(WpeEditor, _old_scol, _old_slns);
        e_x_repaint_desk(WpeEditor->f[WpeEditor->mxedt]);
        return WPE_RESIZE;
