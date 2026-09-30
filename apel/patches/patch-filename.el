$NetBSD$

Restore what upstream removed on 2020-06-25 ("Drop old platforms support"),
so APEL still serves Emacs 20 and XEmacs; pkgsrc has packages that need
it there (misc/lookup, devel/flim, devel/semi).  The functional changes
made upstream since are kept.

--- filename.el.orig
+++ filename.el
@@ -48,7 +48,7 @@ For example, (poly-funcall \\='(car number-to-string) \\='(100)) returns
 (defvar filename-limit-length 21 "Limit size of file-name.")
 
 (defvar filename-replacement-alist
-  '(((?\s ?\t) . "_")
+  '(((?\  ?\t) . "_")
     ((?! ?\" ?# ?$ ?% ?& ?' ?\( ?\) ?* ?/
 	 ?: ?\; ?< ?> ?? ?\[ ?\\ ?\] ?` ?{ ?| ?}) . "_")
     (filename-control-p . ""))
