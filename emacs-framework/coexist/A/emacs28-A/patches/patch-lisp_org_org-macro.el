$NetBSD$

Turning on Org mode expanded macro templates, and a template may hold
arbitrary Elisp, so merely visiting a document ran code the author chose.
This is CVE-2024-30202, upstream commit

	befa9fcaae  org-macro--set-templates: Prevent code evaluation

from the 29.3 emergency release.  Taken unchanged.

--- lisp/org/org-macro.el.orig
+++ lisp/org/org-macro.el
@@ -103,6 +103,13 @@
   (let ((new-templates nil))
     (pcase-dolist (`(,name . ,value) templates)
       (let ((old-definition (assoc name new-templates)))
+        ;; This code can be evaluated unconditionally, as a part of
+        ;; loading Org mode.  We *must not* evaluate any code present
+        ;; inside the Org buffer while loading.  Org buffers may come
+        ;; from various sources, like received email messages from
+        ;; potentially malicious senders.  Org mode might be used to
+        ;; preview such messages and no code evaluation from inside the
+        ;; received Org text should ever happen without user consent.
         (when (and (stringp value) (string-match-p "\\`(eval\\>" value))
           ;; Pre-process the evaluation form for faster macro expansion.
           (let* ((args (org-macro--makeargs value))
@@ -115,7 +122,7 @@
 		      (cadr (read value))
 		    (error
                      (user-error "Invalid definition for macro %S" name)))))
-	    (setq value (eval (macroexpand-all `(lambda ,args ,body)) t))))
+	    (setq value `(lambda ,args ,body))))
         (cond ((and value old-definition) (setcdr old-definition value))
 	      (old-definition)
 	      (t (push (cons name (or value "")) new-templates)))))
