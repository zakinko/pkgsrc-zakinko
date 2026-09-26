$NetBSD$

LaTeX preview was generated for e-mail attachments, and generating it runs
LaTeX on content the sender wrote.  This is CVE-2024-30204, upstream commit
6f9ea396f4 from the 29.3 emergency release.

22.3 ships Org 5.23a, so only the LaTeX half of the 29.3 Org work applies.
Org 5.23a has no (when (display-graphic-p) ...) around the body to extend and
no user-error -- that arrives in 24.1 -- so the test is placed after the
interactive form and raises a plain error.  org-preview-latex-fragment is
reachable only from its key binding here, so nothing calls it expecting a
quiet nil.

CVE-2024-30205, the remote resource fetched without asking, is not here.
5.23a has no org-file-contents at all; editors/emacs23 has that half because
Org 6.33x does.  CVE-2024-39331 is not here either: 5.23a's
org-link-expand-abbrev has no %(...) branch, so the funcall the upstream
commit guards does not exist.

--- lisp/textmodes/org.el.orig
+++ lisp/textmodes/org.el
@@ -222,6 +222,24 @@
    #+STARTUP: noalign"
   :group 'org-startup
   :type 'boolean)
+
+(defvar untrusted-content) ; defined in files.el
+(defvar org--latex-preview-when-risky nil
+  "If non-nil, enable LaTeX preview in Org buffers from unsafe source.
+
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
 
 (defcustom org-insert-mode-line-in-empty-file nil
   "Non-nil means insert the first line setting Org-mode in empty files.
@@ -23846,6 +23864,11 @@
 display all fragments in the buffer.
 The images can be removed again with \\[org-ctrl-c-ctrl-c]."
   (interactive "P")
+  ;; Do not run LaTeX on fragments that came from an untrusted source;
+  ;; generating a preview runs LaTeX on what the sender wrote.
+  ;; CVE-2024-30204.
+  (when (and untrusted-content (not org--latex-preview-when-risky))
+    (error "LaTeX preview is disabled in this buffer (untrusted content)"))
   (org-remove-latex-fragment-image-overlays)
   (save-excursion
     (save-restriction
