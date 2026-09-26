$NetBSD$

font-set-face-font is switched to the new-redisplay version whenever the Emacs
has new redisplay, including on a tty.  There it calls set-face-property with
faces that only exist under a window system.  Require window-system as well.

--- lisp/font.el.orig	Wed Nov 28 20:04:21 2001
+++ lisp/font.el	Thu Oct 17 06:26:04 2002
@@ -996,7 +996,8 @@
     (set-face-property face 'font-specification nil)
     (apply 'set-face-font face font args))))
 
-(if font-running-emacs-new-redisplay
+(if (and font-running-emacs-new-redisplay
+	 window-system)
     (fset 'font-set-face-font 'font-set-face-font-new-redisplay))
 
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
