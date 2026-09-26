$NetBSD$

Load on Emacs 20.  This fork asks for Emacs 24, but on 20.7 only a few
things stand in the way.  mapc, window-list, called-interactively-p,
declare-function, help-print-return-message (20 has
print-help-return-message) and apply-partially, which
elscreen-buffer-list uses, are all unbound there; they are defined here
only when missing.  propertize and replace-regexp-in-string come from
devel/elisp-compat.  Emacs 20 has no header line, so the tabs are not
shown there.

booleanp is unbound on 20.7 too, and add-to-list and
make-obsolete-variable take no third argument there; each stopped
loading with void-function or wrong-number-of-arguments.

--- elscreen.el.orig
+++ elscreen.el
@@ -44,6 +44,34 @@
 
 (require 'dired)
 
+;; Emacs 20 has none of these.  propertize and replace-regexp-in-string
+;; come from elisp-compat; the rest are defined here when missing.
+(eval-and-compile
+  (when (< emacs-major-version 21)
+    (require 'elisp-compat)
+    (or (fboundp 'declare-function)
+        (defmacro declare-function (&rest args) nil))
+    (or (fboundp 'mapc)
+        (defun mapc (function sequence)
+          (mapcar function sequence)
+          sequence))
+    (or (fboundp 'window-list)
+        (defun window-list (&optional frame minibuf window)
+          (let (windows)
+            (walk-windows (lambda (w) (setq windows (cons w windows)))
+                          minibuf frame)
+            (nreverse windows))))
+    (or (fboundp 'called-interactively-p)
+        (defmacro called-interactively-p (&optional kind)
+          '(interactive-p)))
+    (or (fboundp 'help-print-return-message)
+        (defalias 'help-print-return-message 'print-help-return-message))
+    (or (fboundp 'apply-partially)
+        (defun apply-partially (fun &rest args)
+          `(lambda (&rest args2) (apply ',fun (append ',args args2)))))
+    ;; Emacs 20 has no header line, so the tabs are not shown there.
+    (defvar header-line-format nil)))
+
 (declare-function iswitchb-read-buffer "iswitchb")
 
 (defconst elscreen-version "20180321")
@@ -138,7 +166,7 @@
                  (integer :tag "Show (fixed width tab)" :size 4 :value 16)
                  (const :tag "Hide" nil))
   :set (lambda (symbol value)
-         (when (or (booleanp value)
+         (when (or (memq value '(t nil))
                    (and (numberp value)
                         (> value 0)))
            (custom-set-default symbol value)
@@ -146,8 +174,11 @@
              (elscreen-tab-update t))))
   :group 'elscreen)
 
-(make-obsolete-variable 'elscreen-tab-display-create-screen
-                        'elscreen-tab-display-control "2012-04-11")
+(if (< emacs-major-version 21)
+    (make-obsolete-variable 'elscreen-tab-display-create-screen
+                            'elscreen-tab-display-control)
+  (make-obsolete-variable 'elscreen-tab-display-create-screen
+                          'elscreen-tab-display-control "2012-04-11"))
 (defcustom elscreen-tab-display-control t
   "*Non-nil to display control tab at the most left side."
   :tag "Show/Hide the Control Tab"
@@ -1075,7 +1106,9 @@
 
 (defvar elscreen-help-symbol-list nil)
 (defun elscreen-set-help (help-symbol)
-  (add-to-list 'elscreen-help-symbol-list help-symbol t))
+  (unless (member help-symbol elscreen-help-symbol-list)
+    (setq elscreen-help-symbol-list
+          (append elscreen-help-symbol-list (list help-symbol)))))
 (elscreen-set-help 'elscreen-help)
 
 (defun elscreen-help ()
