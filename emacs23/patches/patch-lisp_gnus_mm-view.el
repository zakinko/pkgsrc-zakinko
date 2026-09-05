$NetBSD$

Two unrelated fixes in the same file, because pkgsrc takes one patch per file.

CVE-2017-14482: stop decoding text/enriched and text/richtext parts.  See
patch-lisp_textmodes_enriched.el for what the decoder did and why it goes.
Upstream commit

	9ad0fcc544  Remove unsafe enriched mode translations

released in 25.3.

CVE-2024-30203: Gnus fontifies an inline MIME part by turning on the major
mode for it, and a major mode runs code.  The part came in the mail, so the
sender chose that code.  Upstream commit

	937b9042ad  * lisp/gnus/mm-view.el (mm-display-inline-fontify): Mark
	            contents untrusted.

from the 29.3 emergency release.  The one added line is placed by hand at the
same point: this Emacs does not use with-temp-buffer here -- it makes the
buffer itself, to work around an XEmacs font-lock quirk -- so the line goes
right after that with-current-buffer instead.

The variable it sets comes from patch-lisp_files.el.  Be clear about how far
that reaches here: upstream's reader is elisp-mode.el, which this Emacs does
not have, so what the flag actually stops in this package is the Org LaTeX
preview in patch-lisp_org_org.el, and nothing else.

--- lisp/gnus/mm-view.el.orig
+++ lisp/gnus/mm-view.el
@@ -454,10 +454,6 @@
 	(goto-char (point-max))))
     (save-restriction
       (narrow-to-region b (point))
-      (when (member type '("enriched" "richtext"))
-        (set-text-properties (point-min) (point-max) nil)
-	(ignore-errors
-	  (enriched-decode (point-min) (point-max))))
       (mm-handle-set-undisplayer
        handle
        `(lambda ()
@@ -569,6 +565,11 @@
     ;; `with-current-buffer'/`generate-new-buffer' rather than
     ;; `with-temp-buffer'.
     (with-current-buffer (generate-new-buffer "*fontification*")
+      ;; CVE-2024-30203: what follows fontifies a MIME part that arrived
+      ;; in mail, and fontification runs the major mode, which may run
+      ;; code the sender chose.  Mark the buffer so modes that ask can
+      ;; tell.
+      (setq untrusted-content t)
       (buffer-disable-undo)
       (mm-enable-multibyte)
       (insert (cond ((eq charset 'gnus-decoded)
