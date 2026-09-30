$NetBSD$

Restore what upstream removed on 2020-06-25 ("Drop old platforms support"),
so APEL still serves Emacs 20 and XEmacs; pkgsrc has packages that need
it there (misc/lookup, devel/flim, devel/semi).  The functional changes
made upstream since are kept.

--- poem-e20_3.el.orig
+++ poem-e20_3.el
@@ -39,6 +39,8 @@
   "Return index of character succeeding CHAR whose index is INDEX."
   `(1+ ,index))
 
+(defalias-maybe 'characterp 'char-valid-p)
+
 
 ;;; @ string
 ;;;
