$NetBSD$

mail-parse.el comes with Gnus 5.8 and later; Emacs 20.7 ships Gnus 5.7,
and this file uses it for one RFC 2047 decode.  Load it when it exists
and fall back to the raw header when it does not, so bbdb-hooks still
byte-compiles and runs on Emacs 20.

--- lisp/bbdb-hooks.el.orig	2006-10-09 22:35:41.000000000 +0000
+++ lisp/bbdb-hooks.el
@@ -37,7 +37,9 @@
 
 (require 'bbdb)
 (require 'bbdb-com)
-(require 'mail-parse)
+;; Gnus 5.8's mail-parse; Emacs 20's Gnus 5.7 does not have it.
+(condition-case nil (require 'mail-parse) (error nil))
+(autoload 'mail-decode-encoded-word-string "mail-parse")
 
 (eval-when-compile
   (condition-case()
@@ -149,7 +151,9 @@
                    (progn (end-of-line 2) (point))))))))
         (forward-line 1))
       (and done
-	   (mail-decode-encoded-word-string done)))))
+	   (if (locate-library "mail-parse")
+	       (mail-decode-encoded-word-string done)
+	     done)))))
 
 (defcustom bbdb-ignore-most-messages-alist '()
   "*An alist describing which messages to automatically create BBDB
