$NetBSD$

Emacs 20: make-local-hook before a local add-hook.

--- rng-match.el.orig
+++ rng-match.el
@@ -1572,7 +1572,7 @@
 (defun rng-match-start-document ()
   (rng-ipattern-maybe-init)
   (rng-compile-maybe-init)
-  (add-hook 'rng-schema-change-hook 'rng-schema-changed nil t)
+  (progn (if (fboundp (quote make-local-hook)) (make-local-hook (quote rng-schema-change-hook))) (add-hook (quote rng-schema-change-hook) (quote rng-schema-changed) nil t))
   (setq rng-match-state (rng-compile rng-current-schema)))
 
 (defun rng-match-start-tag-open (name)
