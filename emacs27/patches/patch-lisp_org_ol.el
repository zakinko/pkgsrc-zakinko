$NetBSD$

An abbreviated link may name a function, and expanding the link called it, so
following a link in a document ran code the document chose.  This is
CVE-2024-39331, upstream commit

	c645e1d820  org-link-expand-abbrev: Do not evaluate arbitrary unsafe
	            Elisp code

from the 29.4 release.  Taken unchanged.

--- lisp/org/ol.el.orig
+++ lisp/org/ol.el
@@ -1007,17 +1007,35 @@
       (if (not as)
 	  link
 	(setq rpl (cdr as))
-	(cond
-	 ((symbolp rpl) (funcall rpl tag))
-	 ((string-match "%(\\([^)]+\\))" rpl)
-	  (replace-match
-	   (save-match-data
-	     (funcall (intern-soft (match-string 1 rpl)) tag))
-	   t t rpl))
-	 ((string-match "%s" rpl) (replace-match (or tag "") t t rpl))
-	 ((string-match "%h" rpl)
-	  (replace-match (url-hexify-string (or tag "")) t t rpl))
-	 (t (concat rpl tag)))))))
+        ;; Drop any potentially dangerous text properties like
+        ;; `modification-hooks' that may be used as an attack vector.
+        (substring-no-properties
+	 (cond
+	  ((symbolp rpl) (funcall rpl tag))
+	  ((string-match "%(\\([^)]+\\))" rpl)
+           (let ((rpl-fun-symbol (intern-soft (match-string 1 rpl))))
+             ;; Using `unsafep-function' is not quite enough because
+             ;; Emacs considers functions like `genenv' safe, while
+             ;; they can potentially be used to expose private system
+             ;; data to attacker if abbreviated link is clicked.
+             (if (or (eq t (get rpl-fun-symbol 'org-link-abbrev-safe))
+                     (eq t (get rpl-fun-symbol 'pure)))
+                 (replace-match
+	          (save-match-data
+	            (funcall (intern-soft (match-string 1 rpl)) tag))
+	          t t rpl)
+               (org-display-warning
+                (format "Disabling unsafe link abbrev: %s
+You may mark function safe via (put '%s 'org-link-abbrev-safe t)"
+                        rpl (match-string 1 rpl)))
+               (setq org-link-abbrev-alist-local (delete as org-link-abbrev-alist-local)
+                     org-link-abbrev-alist (delete as org-link-abbrev-alist))
+               link
+	       )))
+	  ((string-match "%s" rpl) (replace-match (or tag "") t t rpl))
+	  ((string-match "%h" rpl)
+	   (replace-match (url-hexify-string (or tag "")) t t rpl))
+	  (t (concat rpl tag))))))))
 
 (defun org-link-open (link &optional arg)
   "Open a link object LINK.
