$NetBSD$

Emacs 20: make-local-hook before a local add-hook.

--- rng-nxml.el.orig
+++ rng-nxml.el
@@ -104,8 +104,8 @@
 	'(rng-validate-mode (:eval (rng-compute-mode-line-string))))
   (cond (rng-nxml-auto-validate-flag
 	 (rng-validate-mode 1)
-	 (add-hook 'nxml-completion-hook 'rng-complete nil t)
-	 (add-hook 'nxml-in-mixed-content-hook 'rng-in-mixed-content-p nil t))
+	 (progn (if (fboundp (quote make-local-hook)) (make-local-hook (quote nxml-completion-hook))) (add-hook (quote nxml-completion-hook) (quote rng-complete) nil t))
+	 (progn (if (fboundp (quote make-local-hook)) (make-local-hook (quote nxml-in-mixed-content-hook))) (add-hook (quote nxml-in-mixed-content-hook) (quote rng-in-mixed-content-p) nil t)))
 	(t
 	 (rng-validate-mode 0)
 	 (remove-hook 'nxml-completion-hook 'rng-complete t)
