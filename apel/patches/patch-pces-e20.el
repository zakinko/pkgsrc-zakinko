$NetBSD$

Restore what upstream removed on 2020-06-25 ("Drop old platforms support"),
so APEL still serves Emacs 20 and XEmacs; pkgsrc has packages that need
it there (misc/lookup, devel/flim, devel/semi).  The functional changes
made upstream since are kept.

--- pces-e20.el.orig
+++ pces-e20.el
@@ -25,8 +25,9 @@
 ;;; Code:
 
 (require 'pces-20)
+(require 'pym)
 
-(defsubst find-coding-system (obj)
+(defsubst-maybe find-coding-system (obj)
   "Return OBJ if it is a coding-system."
   (if (coding-system-p obj)
       obj))
