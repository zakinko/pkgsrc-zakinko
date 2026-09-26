$NetBSD$

comint-input-ring-index is cleared only for the Emacs versions named here, and
upstream stops at fsf-23.  With ilcompat sending Emacs 26 and later to fsf-25,
the index is left pointing into the previous history entry and the next input
is taken from there.  Add fsf-24 and fsf-25.

--- ilisp-xfr.el.orig	2026-09-23 14:40:19
+++ ilisp-xfr.el	2026-09-23 14:40:19
@@ -45,7 +45,9 @@
 			  (eq +ilisp-emacs-version-id+ 'fsf-20)
 			  (eq +ilisp-emacs-version-id+ 'fsf-21)
 			  (eq +ilisp-emacs-version-id+ 'fsf-22)
-			  (eq +ilisp-emacs-version-id+ 'fsf-23))
+			  (eq +ilisp-emacs-version-id+ 'fsf-23)
+			  (eq +ilisp-emacs-version-id+ 'fsf-24)
+			  (eq +ilisp-emacs-version-id+ 'fsf-25))
 		  (setq comint-input-ring-index nil))
 		;; Nuke symbol table
 		(setq ilisp-original nil)
