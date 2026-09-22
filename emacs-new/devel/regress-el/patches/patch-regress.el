$NetBSD$

The loop macro comes from cl, which the file never loads; without it
byte-compilation stops at "for" being an unbound variable.  From Gentoo.

--- regress.el.orig
+++ regress.el
@@ -114,6 +114,8 @@
 ;;  regression test fails and FAILURE-INDICATION is non-nil, it will
 ;;  be printed along with the results.
 
+(eval-when-compile
+  (require 'cl))
 
 ;; Here are some contrived, simple examples.  Much of regress.el
 ;; itself contains regression tests.  Search for "eval-when-compile",
