$NetBSD$

PCE-make-hash-table builds an obarray out of a plain vector.

--- lisp/PCE.el.orig	2026-09-23 16:18:40
+++ lisp/PCE.el	2026-09-23 16:18:40
@@ -93,7 +93,9 @@
 
 (defconst PCE-default-hash-table-size 53)
 (defun PCE-make-hash-table ()
-  (make-vector PCE-default-hash-table-size 0))
+  (if (fboundp 'obarray-make)
+      (obarray-make PCE-default-hash-table-size)
+    (make-vector PCE-default-hash-table-size 0)))
 
 (defsubst PCE-hash-key-to-string (key)
   (cond ((stringp key) key)
