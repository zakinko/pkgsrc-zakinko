$NetBSD$

Emacs 30 turned obarray into a type of its own, so a plain vector made with
make-vector is no longer accepted by intern.  its.el builds several of them
and uses four as obarrays, and the failure is at load time, not at compile
time: every file byte-compiles and then egg.el stops with

	(wrong-type-argument obarrayp [nil nil ...])

its-compaction-integer-table is NOT one of them.  It is read and written with
aref and aset, so it has to stay a vector; turning it into an obarray makes
fourteen of the files under its/ fail to compile with

	Wrong type argument: arrayp, #<obarray n=0>

obarray-make does not exist before Emacs 30, and this package is still built
for emacs20 and emacs21, so choose at run time instead of replacing outright.
--- its.el.orig	2026-09-23 14:26:43
+++ its.el	2026-09-23 15:08:01
@@ -695,7 +695,9 @@
 
 (defun its-map-compaction (map)
   (if its-compaction-enable
-      (let ((its-compaction-hash-table (make-vector 1000 nil))
+      (let ((its-compaction-hash-table (if (fboundp 'obarray-make)
+					   (obarray-make 1000)
+					 (make-vector 1000 nil)))
 	    (its-compaction-integer-table (make-vector 138 nil))
 	    (its-compaction-counter-1 1)
 	    (its-compaction-counter-2 0)
@@ -1357,8 +1359,10 @@
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
@@ -1468,7 +1472,7 @@
 		(?ｐ . ?p)  (?ｑ . ?q)  (?ｒ . ?r)  (?ｓ . ?s)  (?ｔ . ?t)
 		(?ｕ . ?u)  (?ｖ . ?v)  (?ｗ . ?w)  (?ｘ . ?x)  (?ｙ . ?y)
 		(?ｚ . ?z))))
-      (hash (make-vector 100 nil))
+      (hash (if (fboundp 'obarray-make) (obarray-make 100) (make-vector 100 nil)))
       lang pair)
   (while table
     (setq lang (caar table)
