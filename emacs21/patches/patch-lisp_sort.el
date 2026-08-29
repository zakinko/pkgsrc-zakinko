$NetBSD: patch-ba,v 1.1 2007/06/11 13:38:43 markd Exp $

sort-columns hands the field separator to sort(1) after -t, and passed a
newline.  BSD sort refuses that -- "record/field delimiter clash", since the
record separator is a newline too -- so M-x sort-columns did nothing at all on
NetBSD.  A tab works and is what the +0.N -0.M column specs alongside it
assume.

--- lisp/sort.el.orig	2001-07-16 04:15:34.000000000 +1200
+++ lisp/sort.el
@@ -493,7 +493,7 @@ Use \\[untabify] to convert tabs to spac
 	  ;; Use the sort utility if we can; it is 4 times as fast.
 	  ;; Do not use it if there are any properties in the region,
 	  ;; since the sort utility would lose the properties.
-	  (let ((sort-args (list (if reverse "-rt\n" "-t\n")
+	  (let ((sort-args (list (if reverse "-rt\t" "-t\t")
 				 (concat "+0." (int-to-string col-start))
 				 (concat "-0." (int-to-string col-end)))))
 	    (when sort-fold-case
