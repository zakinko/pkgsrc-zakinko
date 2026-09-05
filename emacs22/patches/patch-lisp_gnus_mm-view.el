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

from the 29.3 emergency release.  22.3 neither uses with-temp-buffer here nor
calls generate-new-buffer inside with-current-buffer -- it sets the buffer by
hand, to work around an XEmacs font-lock quirk -- so the line goes right after
that set-buffer.

The variable comes from patch-lisp_files.el.  What reads it in this package is
patch-lisp_textmodes_org.el and nothing else: upstream's other reader,
elisp-mode.el, does not exist in 22.3.

--- lisp/gnus/mm-view.el.orig
+++ lisp/gnus/mm-view.el
@@ -432,11 +432,6 @@
 	(goto-char (point-max))))
     (save-restriction
       (narrow-to-region b (point))
-      (when (or (equal type "enriched")
-		(equal type "richtext"))
-	(set-text-properties (point-min) (point-max) nil)
-	(ignore-errors
-	  (enriched-decode (point-min) (point-max))))
       (mm-handle-set-undisplayer
        handle
        `(lambda ()
@@ -537,6 +532,11 @@
     ;; with-temp-buffer.
     (save-current-buffer
       (set-buffer (generate-new-buffer "*fontification*"))
+      ;; CVE-2024-30203: what follows fontifies a MIME part that arrived
+      ;; in mail, and fontification runs the major mode, which may run
+      ;; code the sender chose.  Mark the buffer so modes that ask can
+      ;; tell.
+      (setq untrusted-content t)
       (unwind-protect
 	  (progn
 	    (buffer-disable-undo)
