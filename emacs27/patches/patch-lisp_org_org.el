$NetBSD$

LaTeX preview was generated for e-mail attachments, and generating it runs
LaTeX on content the sender wrote.  This is CVE-2024-30204, upstream commit

	6f9ea396f4  org-latex-preview: Add protection when `untrusted-content'
	            is non-nil

from the 29.3 emergency release.  Taken unchanged.

--- lisp/org/org.el.orig
+++ lisp/org/org.el
@@ -1076,7 +1076,25 @@
   :version "24.4"
   :package-version '(Org . "8.0")
   :type 'boolean)
+
+(defvar untrusted-content) ; defined in files.el
+(defvar org--latex-preview-when-risky nil
+  "If non-nil, enable LaTeX preview in Org buffers from unsafe source.
 
+Some specially designed LaTeX code may generate huge pdf or log files
+that may exhaust disk space.
+
+This variable controls how to handle LaTeX preview when rendering LaTeX
+fragments that originate from incoming email messages.  It has no effect
+when Org mode is unable to determine the origin of the Org buffer.
+
+An Org buffer is considered to be from unsafe source when the
+variable `untrusted-content' has a non-nil value in the buffer.
+
+If this variable is non-nil, LaTeX previews are rendered unconditionally.
+
+This variable may be renamed or changed in the future.")
+
 (defcustom org-insert-mode-line-in-empty-file nil
   "Non-nil means insert the first line setting Org mode in empty files.
 When the function `org-mode' is called interactively in an empty file, this
@@ -15827,6 +15845,7 @@
   (interactive "P")
   (cond
    ((not (display-graphic-p)) nil)
+   ((and untrusted-content (not org--latex-preview-when-risky)) nil)
    ;; Clear whole buffer.
    ((equal arg '(64))
     (org-clear-latex-preview (point-min) (point-max))
