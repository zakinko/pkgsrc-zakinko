$NetBSD$

Restore what upstream removed on 2020-06-25 ("Drop old platforms support"),
so APEL still serves Emacs 20 and XEmacs; pkgsrc has packages that need
it there (misc/lookup, devel/flim, devel/semi).  The functional changes
made upstream since are kept.

--- pces.el.orig
+++ pces.el
@@ -1,4 +1,4 @@
-;;; pces.el --- Portable Character Encoding Scheme (coding-system) features  -*- lexical-binding: t -*-
+;;; pces.el --- Portable Character Encoding Scheme (coding-system) features
 
 ;; Copyright (C) 1998,1999 Free Software Foundation, Inc.
 
@@ -24,7 +24,23 @@
 
 ;;; Code:
 
-(require 'pces-e20)
+(require 'poe)
+
+(eval-and-compile
+  (unless (fboundp 'open-network-stream)
+    (require 'tcp)))
+
+(cond ((featurep 'xemacs)
+       (if (featurep 'file-coding)
+	   (require 'pces-xfc)
+	 (require 'pces-raw)
+	 ))
+      ((featurep 'mule)
+       (require 'pces-e20)
+       )
+      (t
+       (require 'pces-raw)
+       ))
 
 	 
 ;;; @ end
