$NetBSD$

This require runs before ilcompat is loaded nine lines below, so on an Emacs
without cl-lib it stops here and the stand-in in ilcompat never gets a chance.
Nothing between the two lines needs cl-lib.
--- ilisp.el.orig
+++ ilisp.el
@@ -64,7 +64,9 @@
 ;;; interactively, then the lisp or ilisp comes at the end of the
 ;;; function name, otherwise at the start.
 
-(require 'cl-lib)
+;; cl-lib is absent before Emacs 24.3.  Do not insist on it here: ilcompat,
+;; loaded a few lines below, stands in for it and pulls in cl.
+(require 'cl-lib nil t)
 
 ;;;%Requirements
 (if (string-match "\\`18" emacs-version)
