$NetBSD$

Calc writes the data and command files it feeds to gnuplot into /tmp, under
names that can be worked out in advance.

	(defvar calc-gnuplot-tempfile "/tmp/calc")

	calc-temp-file-name ->  (make-temp-name "/tmp/calcA...")
	                        write-region ... filename

make-temp-name only invents a name; it does not create the file.  Anyone with
write access to /tmp can put a symlink at the name Calc is about to use, and
the write follows it.  Three call sites do this (calc-graph.el:363, :437 and
:502), each followed by write-region.

No CVE was ever filed for this -- the package predates the practice -- but it
is the same shape as CVE-2008-1694 (emacs's vcdiff) and CVE-2008-2142
(fast-lock), which pkgsrc patched in editors/emacs20 and emacs21 in 2008.

Two changes.  make-temp-file creates the file as it names it, so nothing can
get in between; it is used where it exists (Emacs 21.1 and later).  Emacs 20
has no such primitive, so the files are moved out of the shared directory
altogether, into ~/.calc-tmp made 0700 first.  editors/emacs20's fast-lock
patch takes the same way out, dropping "." from the cache directories.

--- calc-graph.el.orig
+++ calc-graph.el
@@ -32,7 +32,12 @@
 ;;; Graphics
 
 ;;; Note that some of the following initial values also occur in calc.el.
-(defvar calc-gnuplot-tempfile "/tmp/calc")
+(defvar calc-gnuplot-tempfile
+  (expand-file-name "calc" (file-name-as-directory
+			    (expand-file-name ".calc-tmp" "~")))
+  "Prefix for the temporary files Calc writes for gnuplot.
+This used to be under /tmp, where the names are predictable and anyone can
+create them first.  Keep them in a directory of the user's own instead.")
 
 (defvar calc-gnuplot-default-device "default")
 (defvar calc-gnuplot-default-output "STDOUT")
@@ -851,12 +856,26 @@
 	    (setq blank t)))))
 )
 
+(defun calc-make-temp-file (prefix)
+  "Return the name of a new temporary file starting with PREFIX.
+make-temp-file creates the file as it names it, so nobody can get in
+between; it arrived in Emacs 21.1.  Without it the best that can be done
+is to make the directory first, owned by the user and not readable by
+anyone else, and take a name inside it."
+  (let ((dir (file-name-directory prefix)))
+    (or (file-directory-p dir)
+	(progn (make-directory dir t)
+	       (set-file-modes dir 448))))	; 0700
+  (if (fboundp 'make-temp-file)
+      (make-temp-file prefix)
+    (make-temp-name prefix)))
+
 (defun calc-temp-file-name (num)
   (while (<= (length calc-graph-file-cache) (1+ num))
     (setq calc-graph-file-cache (nconc calc-graph-file-cache (list nil))))
   (car (or (nth (1+ num) calc-graph-file-cache)
 	   (setcar (nthcdr (1+ num) calc-graph-file-cache)
-		   (list (make-temp-name
+		   (list (calc-make-temp-file
 			  (concat calc-gnuplot-tempfile
 				  (if (<= num 0)
 				      (char-to-string (- ?A num))
