$NetBSD$

Same removed function as in patch-egg.el; this one is reached when a
conversion candidate menu is opened.

string-to-int went the same way; it is reached when a candidate is chosen
with the mouse.

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
@@ -598,7 +599,7 @@
 	  (mouse-choose-completion event)
 	(choose-completion))
       (set-buffer tmp-buf)
-      (setq n (string-to-int (buffer-string))))
+      (setq n (string-to-number (buffer-string))))
     (pop-to-buffer org-buf)
     (while (and item-list (>= n (length (car item-list))))
       (setq l (1+ l)
