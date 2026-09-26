$NetBSD$

backbuf is not an Xft object.  The Cairo backend creates it itself, in
cr_resize(), and draws into it; Xft only happens to be the other user.
Declaring it inside #ifdef HAVE_XFT breaks every build that has X11 but
not Xft, at twelve sites in three files:

  we_debug.c:1269
  we_xterm.c:1090, 1269, 1283
  we_render_cairo.c:160, 178, 188, 190, 196, 203, 215, 271

  we_debug.c:1269:41: error: 'WpeXStruct' has no member named 'backbuf'

configure calls both Xft and Cairo optional, so X11 with neither, and
X11 with Cairo but no Xft, are both configurations it offers.  Moving
the one line out is enough for the eight Cairo sites; the other four
need a runtime check as well, since with neither backend nothing
creates the pixmap.

--- WeXterm.h.orig
+++ WeXterm.h
@@ -53,12 +53,14 @@
  int colors[16];
  WpeMouseShape shape_list[2];
  char *selection;
+ Pixmap backbuf;          /* the X11 back buffer: Xft draws into it, and so
+                             does the Cairo backend, which creates it itself
+                             in cr_resize().  It is not an Xft object. */
 #ifdef HAVE_XFT
  XftFont *xftfont;
  XftDraw *xftdraw;
  XftColor xftcolors[24];   /* 16 base + up to 8 LSP truecolor slots (we_lsp.h
                               LSP_SEM_TC_MAX): a fg index 16+slot picks a slot */
- Pixmap backbuf;
  FcPattern *xftpattern;
  FcFontSet *xftfont_set;
 #endif
