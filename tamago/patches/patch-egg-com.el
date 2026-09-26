$NetBSD$

make-coding-system became define-coding-system in Emacs 22 and was removed in
Emacs 31, so egg-com.el stops with (void-function make-coding-system) once the
obarray問題 is out of the way.

Only two of the old types are used here, 4 (CCL) and 0 (emacs-mule), so define
just those two when the function is missing.  On emacs20, emacs21 and XEmacs,
which all still have it, this defines nothing.
--- egg-com.el.orig	2026-09-23 14:26:43
+++ egg-com.el	2026-09-23 14:28:20
@@ -97,6 +97,24 @@
       (read r0)
       (repeat)))))
 )
+
+;; make-coding-system became define-coding-system in Emacs 22 and was
+;; removed in Emacs 31.  Only two of its types are used below, 4 (CCL) and
+;; 0 (emacs-mule), so supply just those when the function is absent.  On an
+;; Emacs or XEmacs that still has it, this defines nothing.
+(unless (fboundp 'make-coding-system)
+  (defun make-coding-system (name type mnemonic doc &optional flags props)
+    (cond
+     ((eq type 4)
+      (define-coding-system name doc
+	:coding-type 'ccl :mnemonic mnemonic :charset-list '(emacs)
+	:ccl-decoder (car flags) :ccl-encoder (cdr flags)))
+     ((eq type 0)
+      (define-coding-system name doc
+	:coding-type 'emacs-mule :mnemonic mnemonic
+	:charset-list 'emacs-mule))
+     (t (error "make-coding-system: type %S is not supported here" type)))
+    name))
 
 (make-coding-system 'fixed-euc-jp 4 ?W "Coding System for fixed EUC Japanese"
 		    (cons ccl-decode-fixed-euc-jp ccl-encode-fixed-euc-jp))
