$NetBSD: patch-cd,v 1.1 2008/07/13 17:28:34 dholland Exp $

fast-lock-cache-directories names directories that fast-lock writes cache files
into, and a file-local value for it therefore chooses where a buffer's cache is
written.  Marking it risky makes emacs ask before honouring it, which is what
later versions do.  loaddefs.el is generated, but it is what is loaded at
startup, so the property has to be here to take effect before fast-lock is.

--- lisp/loaddefs.el.orig	2008-07-13 12:31:55.000000000 -0400
+++ lisp/loaddefs.el	2008-07-13 12:32:23.000000000 -0400
@@ -5345,6 +5345,8 @@
 ;;;;;;  "fast-lock.el" (14139 58050))
 ;;; Generated autoloads from fast-lock.el
 
+(put (quote fast-lock-cache-directories) (quote risky-local-variable) t)
+
 (autoload (quote fast-lock-mode) "fast-lock" "\
 Toggle Fast Lock mode.
 With arg, turn Fast Lock mode on if and only if arg is positive and the buffer
