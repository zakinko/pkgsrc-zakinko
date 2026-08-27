$NetBSD$

Item 4: find-gc.el built its working tree at the fixed name /tmp/esrc,
destroying and recreating it with csh "rm -rf"/"mkdir" and then reading
generated .rtl files back from it -- a predictable name in a world-writable
directory.  Route it through a per-user 0700 directory (mule-user-temp-
directory) instead.  Upstream moved find-gc out of the shipped lisp into
admin/ rather than fixing it.

--- lisp/find-gc.el.orig	1995-01-01 00:00:00.000000000 +0000
+++ lisp/find-gc.el
@@ -73,29 +73,38 @@
 ;;; This produces an a-list of functions in subrs-called.  The cdr of
 ;;; each entry is a list of functions which the function in car calls.
 
+;; This working directory was the fixed name /tmp/esrc, blown away and
+;; recreated with `csh -c "rm -rf ..."'/`"mkdir ..."': a predictable name in
+;; a world-writable place another user could pre-plant.  Put it in a per-user
+;; 0700 directory instead.  See mule-user-temp-directory.
+(defun find-gc-work-dir ()
+  "Return the private working directory trace-call-tree unpacks sources into."
+  (expand-file-name "esrc" (mule-user-temp-directory)))
+
 (defun trace-call-tree (&optional already-setup)
   (message "Setting up directories...")
   (or already-setup
-      (progn
+      (let ((esrc (find-gc-work-dir)))
 	;; Gee, wouldn't a built-in "system" function be handy here.
-	(call-process "csh" nil nil nil "-c" "rm -rf /tmp/esrc")
-	(call-process "csh" nil nil nil "-c" "mkdir /tmp/esrc")
+	(call-process "csh" nil nil nil "-c" (format "rm -rf %s" esrc))
+	(call-process "csh" nil nil nil "-c" (format "mkdir %s" esrc))
 	(call-process "csh" nil nil nil "-c"
-		      (format "ln -s %s/*.[ch] /tmp/esrc"
-			      emacs-source-directory))))
+		      (format "ln -s %s/*.[ch] %s"
+			      emacs-source-directory esrc))))
   (save-excursion
     (set-buffer (get-buffer-create "*Trace Call Tree*"))
     (setq subrs-called nil)
     (let ((case-fold-search nil)
 	  (files source-files)
+	  (esrc (find-gc-work-dir))
 	  name entry)
       (while files
 	(message "Compiling %s..." (car files))
 	(call-process "csh" nil nil nil "-c"
-		      (format "gcc -dr -c /tmp/esrc/%s -o /dev/null"
-			      (car files)))
+		      (format "gcc -dr -c %s/%s -o /dev/null"
+			      esrc (car files)))
 	(erase-buffer)
-	(insert-file-contents (concat "/tmp/esrc/" (car files) ".rtl"))
+	(insert-file-contents (expand-file-name (concat (car files) ".rtl") esrc))
 	(while (re-search-forward ";; Function \\|(call_insn " nil t)
 	  (if (= (char-after (- (point) 3)) ?o)
 	      (progn
@@ -111,7 +120,7 @@
 						       (match-end 1))))
 		  (or (memq name (cdr entry))
 		      (setcdr entry (cons name (cdr entry))))))))
-	(delete-file (concat "/tmp/esrc/" (car files) ".rtl"))
+	(delete-file (expand-file-name (concat (car files) ".rtl") esrc))
 	(setq files (cdr files)))))
 )
 
