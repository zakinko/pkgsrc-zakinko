$NetBSD$

The XEmacs colour probe tested only for device-class; Emacs 30 has a
device-class of its own (frame.el) but no selected-device, so loading
yatexlib.el without a display died with a void selected-device.

--- yatexlib.el.orig
+++ yatexlib.el
@@ -27,7 +27,7 @@
 
 (defvar YaTeX-display-color-p
   (or (and (fboundp 'display-color-p) (display-color-p))
-      (and (fboundp 'device-class)
+      (and (fboundp 'device-class) (fboundp 'selected-device)
 	   (eq 'color (device-class (selected-device))))
       window-system)  ; falls down lazy check..
   "Current display's capability of expressing colors.")
