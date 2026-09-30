$NetBSD$

Restore what upstream removed on 2020-06-25 ("Drop old platforms support"),
so APEL still serves Emacs 20 and XEmacs; pkgsrc has packages that need
it there (misc/lookup, devel/flim, devel/semi).  The functional changes
made upstream since are kept.

--- calist.el.orig
+++ calist.el
@@ -26,7 +26,8 @@
 
 ;;; Code:
 
-(require 'cl-lib)
+(eval-when-compile (require 'cl))
+
 (require 'alist)
 
 (defvar calist-package-alist nil)
@@ -284,11 +285,11 @@ even if other rules are matched for ALIST."
 					  (delete ret (copy-alist calist))))
 				   (cdr ctree)))
 		   (setcdr ctree
-			   (cl-list* (list t)
-				     (cons (cdr ret)
-					   (calist-to-ctree
-					    (delete ret (copy-alist calist))))
-				     (cdr ctree)))
+			   (list* (list t)
+				  (cons (cdr ret)
+					(calist-to-ctree
+					 (delete ret (copy-alist calist))))
+				  (cdr ctree)))
 		   ))
 	     (catch 'tag
 	       (while values
