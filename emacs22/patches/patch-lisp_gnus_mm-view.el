$NetBSD$

The mm-view half of the CVE-2017-14482 fix: stop decoding text/enriched and
text/richtext parts.  See patch-lisp_textmodes_enriched.el for what the
decoder did and why it goes.  Upstream commit

	9ad0fcc544  Remove unsafe enriched mode translations

released in 25.3.

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
