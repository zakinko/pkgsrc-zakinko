$NetBSD$

make-local-hook went away in Emacs 22.  Since Emacs 21.1 add-hook creates the
local hook itself when its LOCAL argument is non-nil, and the call here is
immediately followed by exactly such an add-hook, so there is nothing left for
it to do.  Without this, byte-compilation is clean and activating any of the
eleven input methods egg registers stops with

	(void-function make-local-hook)

--- egg.el.orig
+++ egg.el
@@ -169,7 +169,8 @@
       (setq egg-modeless-mode t))
     (setq inactivate-current-input-method-function 'egg-mode)
     (setq describe-current-input-method-function 'egg-help)
-    (make-local-hook 'input-method-activate-hook)
+    (if (fboundp 'make-local-hook)
+	(make-local-hook 'input-method-activate-hook))
     (add-hook 'input-method-activate-hook 'its-set-mode-line-title nil t)
     (if (eq (selected-window) (minibuffer-window))
 	(add-hook 'minibuffer-exit-hook 'egg-exit-from-minibuffer))
