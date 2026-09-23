$NetBSD$

ilcompat.el stops at Emacs 25 and everything after it falls through to the
fsf-18 branch, which then loads a compatibility file written for Emacs 18 and
dies on (void-variable comint-version).  Emacs 26 and later behave close
enough to 25 for ILISP's purposes, so send them there.

--- ilcompat.el.orig	2026-09-23 14:35:11
+++ ilcompat.el	2026-09-23 14:35:11
@@ -33,6 +33,10 @@
 	 'fsf-24)
 	((string-match "^25" emacs-version)
 	 'fsf-25)
+	;; Emacs 26 and later: no layer of their own, and falling through to
+	;; fsf-18 loads a compatibility file written for Emacs 18.
+	((string-match "^\\([3-9][0-9]\\|2[6-9]\\)" emacs-version)
+	 'fsf-25)
 	(t 'fsf-18))
   "The major version of (X)Emacs ILISP is running in.
 Declared as '(member fsf-19 fsf-19 fsf-20 fsf-21 fsf-22 fsf-23 fsf-24
