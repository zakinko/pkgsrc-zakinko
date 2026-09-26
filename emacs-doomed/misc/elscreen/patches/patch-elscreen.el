$NetBSD$

Load on Emacs 20.  booleanp is Emacs 22 and the third argument of
add-to-list is Emacs 21; each stopped loading with void-function or
wrong-number-of-arguments.  propertize comes from devel/elisp-compat.

--- elscreen.el.orig
+++ elscreen.el
@@ -26,6 +26,7 @@
 
 (provide 'elscreen)
 (require 'alist)
+(if (< emacs-major-version 21) (require 'elisp-compat))
 (eval-when-compile
   (require 'static))
 
@@ -133,7 +134,7 @@
                  (integer :tag "Show (fixed width tab)" :size 4 :value 16)
                  (const :tag "Hide" nil))
   :set (lambda (symbol value)
-         (when (or (booleanp value)
+         (when (or (memq value (quote (t nil)))
                    (and (numberp value)
                         (> value 0)))
            (custom-set-default symbol value)
@@ -1036,7 +1037,9 @@
 
 (defvar elscreen-help-symbol-list nil)
 (defun elscreen-set-help (help-symbol)
-  (add-to-list 'elscreen-help-symbol-list help-symbol t))
+  (unless (member help-symbol elscreen-help-symbol-list)
+    (setq elscreen-help-symbol-list
+	  (append elscreen-help-symbol-list (list help-symbol)))))
 (elscreen-set-help 'elscreen-help)
 
 (defun elscreen-help ()
