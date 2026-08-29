$NetBSD$

Mark fast-lock-cache-directories risky, so emacs asks before honouring a
file-local value for it.  loaddefs.el is generated, but it is what is loaded at
startup, so the property has to be here to take effect before fast-lock is.
The variable itself is dealt with in patch-lisp_fast-lock.el.

--- lisp/loaddefs.el.orig	2003-03-19 02:36:18.000000000 +1200
+++ lisp/loaddefs.el
@@ -6963,6 +6963,8 @@ of colors that the current display can h
 ;;;;;;  "fast-lock.el" (15611 31344))
 ;;; Generated autoloads from fast-lock.el
 
+(put (quote fast-lock-cache-directories) (quote risky-local-variable) t)
+
 (autoload (quote fast-lock-mode) "fast-lock" "\
 Toggle Fast Lock mode.
 With arg, turn Fast Lock mode on if and only if arg is positive and the buffer
