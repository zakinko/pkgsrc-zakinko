$NetBSD$

Restore what upstream removed on 2020-06-25 ("Drop old platforms support"),
so APEL still serves Emacs 20 and XEmacs; pkgsrc has packages that need
it there (misc/lookup, devel/flim, devel/semi).  The functional changes
made upstream since are kept.

--- product.el.orig
+++ product.el
@@ -1,4 +1,4 @@
-;;; product.el --- Functions for product version information  -*- lexical-binding: t -*-
+;;; product.el --- Functions for product version information.
 
 ;; Copyright (C) 1999,2000 Free Software Foundation, Inc.
 
@@ -293,12 +293,13 @@ The 1st argument is a product structure.  The rest arguments are ARGS."
 PRODUCT is a product structure which returned by `product-define'."
   (let (dest)
     (product-for-each product nil
-     (lambda (product)
-       (let ((str (product-string-1 product nil)))
-	 (if str
-	     (setq dest (if dest
-			    (concat dest " " str)
-			  str))))))
+     (function
+      (lambda (product)
+	(let ((str (product-string-1 product nil)))
+	  (if str
+	      (setq dest (if dest
+			     (concat dest " " str)
+			   str)))))))
     dest))
 
 (defun product-string-verbose (product)
@@ -306,12 +307,13 @@ PRODUCT is a product structure which returned by `product-define'."
 PRODUCT is a product structure which returned by `product-define'."
   (let (dest)
     (product-for-each product nil
-     (lambda (product)
-       (let ((str (product-string-1 product t)))
-	 (if str
-	     (setq dest (if dest
-			    (concat dest " " str)
-			  str))))))
+     (function
+      (lambda (product)
+	(let ((str (product-string-1 product t)))
+	  (if str
+	      (setq dest (if dest
+			     (concat dest " " str)
+			   str)))))))
     dest))
 
 (defun product-version-compare (v1 v2)
@@ -337,8 +339,9 @@ REQUIRE-VERSION is a list of integer."
   "List all products information."
   (let (dest)
     (mapatoms
-     (lambda (sym)
-       (setq dest (cons (symbol-value sym) dest)))
+     (function
+      (lambda (sym)
+	(setq dest (cons (symbol-value sym) dest))))
      product-obarray)
     dest))
 
@@ -372,5 +375,54 @@ VERSTR is a string."
 (provide 'product)			; beware of circular dependency.
 (require 'apel-ver)			; these two files depend on each other.
 (product-provide 'product 'apel-ver)
+
+
+;;; @ Define emacs versions.
+;;;
+
+(require 'pym)
+
+(defconst-maybe emacs-major-version
+  (progn (string-match "^[0-9]+" emacs-version)
+	 (string-to-int (substring emacs-version
+				   (match-beginning 0)(match-end 0))))
+  "Major version number of this version of Emacs.")
+(defconst-maybe emacs-minor-version
+  (progn (string-match "^[0-9]+\\.\\([0-9]+\\)" emacs-version)
+	 (string-to-int (substring emacs-version
+				   (match-beginning 1)(match-end 1))))
+  "Minor version number of this version of Emacs.")
+
+;;(or (product-find "emacs")
+;;    (progn
+;;      (product-define "emacs")
+;;      (cond
+;;       ((featurep 'meadow)
+;;	(let* ((info (product-parse-version-string (Meadow-version)))
+;;	       (version (nth 0 info))
+;;	       (code-name (nth 1 info))
+;;	       (version-string (nth 2 info)))
+;;	  (product-set-version-string
+;;	   (product-define "Meadow" "emacs" version code-name)
+;;	   version-string)
+;;	  (product-provide 'Meadow "Meadow"))
+;;	(and (featurep 'mule)
+;;	     (let* ((info (product-parse-version-string mule-version))
+;;		    (version (nth 0 info))
+;;		    (code-name (nth 1 info))
+;;		    (version-string (nth 2 info)))
+;;	       (product-set-version-string
+;;		(product-define "MULE" "Meadow" version code-name)
+;;		version-string)
+;;	       (product-provide 'mule "MULE")))
+;;	(let* ((info (product-parse-version-string emacs-version))
+;;	       (version (nth 0 info))
+;;	       (code-name (nth 1 info))
+;;	       (version-string (nth 2 info)))
+;;	  (product-set-version-string
+;;	   (product-define "Emacs" "Meadow" version code-name)
+;;	   version-string)
+;;	  (product-provide 'emacs "Emacs")))
+;;       )))
 
 ;;; product.el ends here
