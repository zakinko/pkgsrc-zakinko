$NetBSD$

Emacs 30 turned obarray into a type of its own, so a plain vector made with
make-vector is no longer accepted by intern.  its.el builds five of them and
uses them as obarrays, and the failure is at load time, not at compile time:
every file byte-compiles and then egg.el stops with

	(wrong-type-argument obarrayp [nil nil ...])

obarray-make does not exist before Emacs 30, and this package is still built
for emacs20 and emacs21, so choose at run time instead of replacing it outright.
--- its.el.orig	2026-09-23 14:26:43
+++ its.el	2026-09-23 14:26:43
@@ -695,8 +695,12 @@
 
 (defun its-map-compaction (map)
   (if its-compaction-enable
-      (let ((its-compaction-hash-table (make-vector 1000 nil))
-	    (its-compaction-integer-table (make-vector 138 nil))
+      (let ((its-compaction-hash-table (if (fboundp 'obarray-make)
+					   (obarray-make 1000)
+					 (make-vector 1000 nil)))
+	    (its-compaction-integer-table (if (fboundp 'obarray-make)
+					      (obarray-make 138)
+					    (make-vector 138 nil)))
 	    (its-compaction-counter-1 1)
 	    (its-compaction-counter-2 0)
 	    (its-compaction-list nil))
@@ -1357,8 +1361,10 @@
   (interactive)
   (its-convert (lambda (str lang) (japanese-katakana str))))
 
-(defconst its-full-half-table (make-vector 100 nil))
-(defconst its-half-full-table (make-vector 100 nil))
+(defconst its-full-half-table
+  (if (fboundp 'obarray-make) (obarray-make 100) (make-vector 100 nil)))
+(defconst its-half-full-table
+  (if (fboundp 'obarray-make) (obarray-make 100) (make-vector 100 nil)))
 
 (let ((table '((Japanese
 		(?　 . ?\ ) (?， . ?,)  (?． . ?.)  (?、 . ?,)  (?。 . ?.)
@@ -1468,7 +1474,7 @@
 		(?ｐ . ?p)  (?ｑ . ?q)  (?ｒ . ?r)  (?ｓ . ?s)  (?ｔ . ?t)
 		(?ｕ . ?u)  (?ｖ . ?v)  (?ｗ . ?w)  (?ｘ . ?x)  (?ｙ . ?y)
 		(?ｚ . ?z))))
-      (hash (make-vector 100 nil))
+      (hash (if (fboundp 'obarray-make) (obarray-make 100) (make-vector 100 nil)))
       lang pair)
   (while table
     (setq lang (caar table)
