$NetBSD$

Emacs 30 turned obarray into a type of its own, so a plain vector made
with make-vector is no longer accepted by intern.  Every file here byte-compiles
and then PCE.el, iiimcf-UI.el and iiimcf-sc.el stop while loading with

	Wrong type argument: obarrayp, [nil nil ...]

un-define is a Mule-UCS file, read only to get the UTF-16 coding systems.
Emacs 22 and later have them, and iiimp.el already falls back to what is there,
so the require can be optional.  That is also what tied this package to emacs20:
editors/mule-ucs accepts emacs20 alone.

--- lisp/EIMIL.el.orig	2026-09-23 16:18:40
+++ lisp/EIMIL.el	2026-09-23 16:18:40
@@ -48,7 +48,7 @@
 
 ;;; Code:
 
-(require 'un-define)
+(require 'un-define nil t)
 
 (defvar EIMIL-cache-directory "~/.eimil")
 
@@ -223,11 +223,11 @@
   (let ((eobj
 	 (if base-eobj
 	     (let ((eobj (copy-sequence base-eobj)))
-	       (aset eobj 3 (make-vector EIMIL-obarray-size 0)) ; private obarray
+	       (aset eobj 3 (if (fboundp 'obarray-make) (obarray-make EIMIL-obarray-size) (make-vector EIMIL-obarray-size 0))) ; private obarray
 	       eobj)
 	   (vector nil nil
-		   (make-vector EIMIL-obarray-size 0)
-		   (make-vector EIMIL-obarray-size 0)
+		   (if (fboundp 'obarray-make) (obarray-make EIMIL-obarray-size) (make-vector EIMIL-obarray-size 0))
+		   (if (fboundp 'obarray-make) (obarray-make EIMIL-obarray-size) (make-vector EIMIL-obarray-size 0))
 		   nil nil nil nil nil nil nil nil)))
 	sym)
     (if base-eobj
@@ -339,11 +339,11 @@
     destob))
 
 (defun EIMIL-copy-pubobarray (ob)
-  (let ((result (make-vector EIMIL-obarray-size 0)))
+  (let ((result (if (fboundp 'obarray-make) (obarray-make EIMIL-obarray-size) (make-vector EIMIL-obarray-size 0))))
     (EIMIL-copy-obarray-1 ob result result)))
 
 (defun EIMIL-copy-privobarray (ob pubobarray)
-  (let ((result (make-vector EIMIL-obarray-size 0)))
+  (let ((result (if (fboundp 'obarray-make) (obarray-make EIMIL-obarray-size) (make-vector EIMIL-obarray-size 0))))
     (EIMIL-copy-obarray-1 ob result pubobarray)))
 
 (defun EIMIL-copy-eobj (eobj)
