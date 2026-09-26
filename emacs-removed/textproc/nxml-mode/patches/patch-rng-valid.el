$NetBSD$

Emacs 20: make-local-hook before a local add-hook.

--- rng-valid.el.orig
+++ rng-valid.el
@@ -262,11 +262,11 @@
 			      (not no-change-schema)))
 		 (rng-auto-set-schema t)))
 	   (unless rng-current-schema (rng-set-schema-file-1 nil))
-	   (add-hook 'rng-schema-change-hook 'rng-validate-clear nil t)
-	   (add-hook 'after-change-functions 'rng-after-change-function nil t)
-	   (add-hook 'kill-buffer-hook 'rng-kill-timers nil t)
-	   (add-hook 'echo-area-clear-hook 'rng-echo-area-clear-function nil t)
-	   (add-hook 'post-command-hook 'rng-maybe-echo-error-at-point nil t)
+	   (progn (if (fboundp (quote make-local-hook)) (make-local-hook (quote rng-schema-change-hook))) (add-hook (quote rng-schema-change-hook) (quote rng-validate-clear) nil t))
+	   (progn (if (fboundp (quote make-local-hook)) (make-local-hook (quote after-change-functions))) (add-hook (quote after-change-functions) (quote rng-after-change-function) nil t))
+	   (progn (if (fboundp (quote make-local-hook)) (make-local-hook (quote kill-buffer-hook))) (add-hook (quote kill-buffer-hook) (quote rng-kill-timers) nil t))
+	   (progn (if (fboundp (quote make-local-hook)) (make-local-hook (quote echo-area-clear-hook))) (add-hook (quote echo-area-clear-hook) (quote rng-echo-area-clear-function) nil t))
+	   (progn (if (fboundp (quote make-local-hook)) (make-local-hook (quote post-command-hook))) (add-hook (quote post-command-hook) (quote rng-maybe-echo-error-at-point) nil t))
 	   (rng-match-init-buffer)
 	   (rng-activate-timers)
 	   ;; Start validating right away if the buffer is visible.
