$NetBSD$

obarray itself is let-bound to a plain vector here, which Emacs 30
no longer accepts.  Nothing in the file names it as an obarray, so grepping for
make-vector alone does not find it.

--- lisp/iiimcf.el.orig	2026-09-23 16:18:40
+++ lisp/iiimcf.el	2026-09-23 16:18:40
@@ -326,7 +326,7 @@
     (char-undefined 0)))
 
 (defconst iiimcf-keycode-hash-obarray
-  (let ((obarray (make-vector 71 nil))
+  (let ((obarray (if (fboundp 'obarray-make) (obarray-make 71) (make-vector 71 nil)))
 	(sl iiimcf-keycode-spec-alist)
 	el sym)
     (while (setq el (car sl))
