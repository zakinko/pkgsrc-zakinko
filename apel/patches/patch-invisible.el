$NetBSD$

Restore what upstream removed on 2020-06-25 ("Drop old platforms support"),
so APEL still serves Emacs 20 and XEmacs; pkgsrc has packages that need
it there (misc/lookup, devel/flim, devel/semi).  The functional changes
made upstream since are kept.

--- invisible.el.orig
+++ invisible.el
@@ -24,7 +24,13 @@
 
 ;;; Code:
 
-(require 'inv-23)
+(cond
+ ((featurep 'xemacs)
+  (require 'inv-xemacs))
+ ((>= emacs-major-version 23)
+  (require 'inv-23))
+ (t
+  (require 'inv-19)))
 
 
 ;;; @ end
