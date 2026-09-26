$NetBSD$

Emacs 20: load nxml-e20.el instead of refusing Mule-UCS, and call
make-local-hook before the local add-hook, without which Emacs 20 puts
the function into the global hook and runs it in every buffer.

--- nxml-mode.el.orig
+++ nxml-mode.el
@@ -33,8 +33,7 @@
 
 ;;; Code:
 
-(when (featurep 'mucs)
-  (error "nxml-mode is not compatible with Mule-UCS"))
+(if (< emacs-major-version 21) (require (quote nxml-e20)))
 
 (require 'xmltok)
 (require 'nxml-enc)
@@ -575,9 +574,14 @@
 	(nxml-clear-inside (point-min) (point-max))
 	(nxml-with-invisible-motion
 	  (nxml-scan-prolog)))))
+  ;; Emacs 20 needs make-local-hook before a local add-hook, or the
+  ;; function lands in the global value and runs in every buffer.
+  (when (fboundp (quote make-local-hook))
+    (make-local-hook (quote fontification-functions))
+    (make-local-hook (quote after-change-functions)))
   (when nxml-syntax-highlight-flag
-    (add-hook 'fontification-functions 'nxml-fontify nil t))
-  (add-hook 'after-change-functions 'nxml-after-change nil t)
+    (add-hook (quote fontification-functions) (quote nxml-fontify) nil t))
+  (add-hook (quote after-change-functions) (quote nxml-after-change) nil t)
   (add-hook 'write-contents-hooks 'nxml-prepare-to-save)
   (when (not (and (buffer-file-name) (file-exists-p (buffer-file-name))))
     (when (and nxml-default-buffer-file-coding-system
