$NetBSD$

Emacs 20.7's rmailsum.el has no (provide 'rmailsum), so require signals
"Required feature rmailsum was not provided" after loading it.  The
file is loaded either way; ignore the missing feature.

--- lisp/bbdb-rmail.el.orig	2005-09-05 17:13:18.000000000 +0000
+++ lisp/bbdb-rmail.el
@@ -24,7 +24,8 @@
 (require 'bbdb)
 (require 'bbdb-com)
 (require 'rmail)
-(require 'rmailsum)
+;; Emacs 20's rmailsum.el does not provide itself.
+(condition-case nil (require 'rmailsum) (error nil))
 (require 'mailheader)
 
 
