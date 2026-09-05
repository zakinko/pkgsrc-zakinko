$NetBSD$

Gnus fontifies an inline MIME part by turning on the major mode for it, and a
major mode runs code.  The part came in the mail, so the sender chose that
code.  This is CVE-2024-30203, upstream commit

	937b9042ad  * lisp/gnus/mm-view.el (mm-display-inline-fontify): Mark
	            contents untrusted.

from the 29.3 emergency release.  The one added line is placed by hand at the
same point, right after the with-temp-buffer that receives the part.

The variable it sets comes from patch-lisp_files.el; what reads it here is
patch-lisp_progmodes_elisp-mode.el.

--- lisp/gnus/mm-view.el.orig
+++ lisp/gnus/mm-view.el
@@ -463,6 +463,11 @@
 	  (setq coding-system (mm-find-buffer-file-coding-system)))
 	(setq text (buffer-string))))
     (with-temp-buffer
+      ;; CVE-2024-30203: what follows fontifies a MIME part that arrived
+      ;; in mail, and fontification runs the major mode, which may run
+      ;; code the sender chose.  Mark the buffer so modes that ask can
+      ;; tell.
+      (setq untrusted-content t)
       (buffer-disable-undo)
       (mm-enable-multibyte)
       (insert (cond ((eq charset 'gnus-decoded)
