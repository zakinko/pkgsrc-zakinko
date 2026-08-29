$NetBSD$

mucs-ccl-register returns its forms wrapped in a progn, but the caller splices
the result into a larger form, so the progn swallows the embedding information
that mucs-notify-embedment collected.  Return the list of forms instead.

--- lisp/mucs-ccl.el.orig	Thu Apr 17 01:50:50 2003
+++ lisp/mucs-ccl.el	Thu Apr 17 01:52:12 2003
@@ -639,10 +639,9 @@
       (mucs-notify-embedment 'mucs-ccl-required name)
       (setq ccl-pgm-list (cdr ccl-pgm-list)))
 ;   (message "MCCLREGFIN:%S" result)
-    `(progn
-       (setq mucs-ccl-facility-alist
-	     (quote ,mucs-ccl-facility-alist))
-       ,@result)))
+    `((setq mucs-ccl-facility-alist
+	    (quote ,mucs-ccl-facility-alist))
+      ,@result)))
 
 ;;; Add hook for embedding translation informations to a package.
 (add-hook 'mucs-package-definition-end-hook
