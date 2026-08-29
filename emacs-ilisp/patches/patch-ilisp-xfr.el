$NetBSD$

ilisp-xfr.el clears comint-input-ring-index only for fsf-19, fsf-20 and
fsf-21.  On later Emacsen the index is left pointing into the previous history
entry, and the next input is taken from there.  Add fsf-22, fsf-23 and fsf-24.

--- ilisp-xfr.el.orig	2002-05-24 05:41:42.000000000 +0900
+++ ilisp-xfr.el	2013-06-19 19:02:24.000000000 +0900
@@ -45,7 +45,10 @@ If we have a complete sexp, send it.  Ot
 		;;       25/11/94 Marco Antoniotti
 		(when (or (eq +ilisp-emacs-version-id+ 'fsf-19)
 			  (eq +ilisp-emacs-version-id+ 'fsf-20)
-			  (eq +ilisp-emacs-version-id+ 'fsf-21))
+			  (eq +ilisp-emacs-version-id+ 'fsf-21)
+			  (eq +ilisp-emacs-version-id+ 'fsf-22)
+			  (eq +ilisp-emacs-version-id+ 'fsf-23)
+			  (eq +ilisp-emacs-version-id+ 'fsf-24))
 		  (setq comint-input-ring-index nil))
 		;; Nuke symbol table
 		(setq ilisp-original nil)
