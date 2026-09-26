$NetBSD$

ilisp-set-doc replaces the docstring of a compiled function by taking the
byte-code object apart and rebuilding it with make-byte-code.  Emacs 30
changed the layout of those objects, so the rebuild signals "Invalid byte-code
object" and loading ilisp stops.

Only the docstring is at stake, and nothing reads it back, so let the attempt
fail quietly instead of taking the whole package down with it.

--- ilisp-mod.el.orig	2026-09-23 14:35:11
+++ ilisp-mod.el	2026-09-23 14:35:11
@@ -50,11 +50,17 @@
 	       (setcar ndoc-cdr string))))
 	  (t
 	   ;; it's an emacs19 compiled-code object
-	   (let ((new-code (ilisp-byte-code-to-list old-function)))
-	     (if (nthcdr 4 new-code)
-		 (setcar (nthcdr 4 new-code) string)
-	       (setcdr (nthcdr 3 new-code) (cons string nil)))
-	     (fset function (apply 'make-byte-code new-code)))))))
+	   ;; Only the docstring is being replaced here.  Emacs 30 changed the
+	   ;; layout of byte-code objects, so taking one apart and rebuilding
+	   ;; it with make-byte-code now signals.  Nothing depends on the new
+	   ;; docstring, so give up quietly when that happens.
+	   (condition-case nil
+	       (let ((new-code (ilisp-byte-code-to-list old-function)))
+		 (if (nthcdr 4 new-code)
+		     (setcar (nthcdr 4 new-code) string)
+		   (setcdr (nthcdr 3 new-code) (cons string nil)))
+		 (fset function (apply 'make-byte-code new-code)))
+	     (error nil))))))
 
 
 
