$NetBSD$

Same removed function as in patch-egg.el; this one is reached when a
conversion candidate menu is opened.

--- menudiag.el.orig
+++ menudiag.el
@@ -503,7 +503,8 @@
   (make-local-variable 'inhibit-read-only)
   (setq buffer-read-only t
 	inhibit-read-only nil)
-  (make-local-hook 'post-command-hook)
+  (if (fboundp 'make-local-hook)
+      (make-local-hook 'post-command-hook))
   (add-hook 'post-command-hook 'menudiag-selection-align-to-item nil t)
   (use-local-map menudiag-selection-map)
   (setq mode-name "Menudiag Selection")
