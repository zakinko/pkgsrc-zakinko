$NetBSD$

make-obsolete requires its WHEN argument since Emacs 29; icicles-fn.el
fails to load without it.  From Gentoo.

--- icicles-fn.el.orig
+++ icicles-fn.el
@@ -4264,7 +4264,7 @@
 
 
 (defalias 'icicle-scatter 'icicle-scatter-re)
-(make-obsolete 'icicle-scatter 'icicle-scatter-re) ; 2018-01-14
+(make-obsolete 'icicle-scatter 'icicle-scatter-re "2018-01-14")
 
 (defun icicle-scatter-re (string)
   "Returns a regexp that matches a scattered version of STRING.
