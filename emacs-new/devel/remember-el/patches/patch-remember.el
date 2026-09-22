$NetBSD$

define-obsolete-function-alias requires its WHEN argument since Emacs 29.
From Gentoo.

--- remember.el.orig
+++ remember.el
@@ -462,7 +462,7 @@
 
 ;; Org needs this
 (if (fboundp 'define-obsolete-function-alias)
-    (define-obsolete-function-alias 'remember-buffer 'remember-finalize)
+    (define-obsolete-function-alias 'remember-buffer 'remember-finalize "")
   (defalias 'remember-buffer 'remember-finalize))
 
 (defun remember-destroy ()
