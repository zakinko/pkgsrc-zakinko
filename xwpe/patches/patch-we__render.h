$NetBSD$

X11 without Cairo does not link.  The no-op stubs are chosen on
NO_XWINDOWS, but the real ones live in we_render_cairo.c, whose whole
body sits inside #ifdef HAVE_CAIRO / #ifdef HAVE_PANGO -- and configure
calls both of those optional.  So an X11 build with no Cairo takes the
#else branch, declares the two functions, and nothing defines them:

  we_mouse.c:(.text+0xd8e): undefined reference to `wpe_chrome_hit_vthumb'
  we_mouse.c:(.text+0x2931): undefined reference to `wpe_chrome_hit_hthumb'

we_mouse.c calls them from plain #if MOUSE code, which is why every X11
build reaches them.  Pick the stubs on what actually decides whether
we_render_cairo.c is compiled.

--- we_render.h.orig
+++ we_render.h
@@ -49,7 +49,7 @@
 
 int wpe_render_cairo_init(void);
 void wpe_render_chrome(void);
-#ifdef NO_XWINDOWS
+#if defined(NO_XWINDOWS) || !defined(HAVE_CAIRO) || !defined(HAVE_PANGO)
 /* The Cairo chrome (the fluid scrollbar thumb) is X11-only; with no X11 there
    is no chrome, so these hit-tests can never match.  Inline no-op stubs let the
    shared mouse code (we_mouse.c) link in a --without-x build, where
