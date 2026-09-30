$NetBSD$

Restore what upstream removed on 2020-06-25 ("Drop old platforms support"),
so APEL still serves Emacs 20 and XEmacs; pkgsrc has packages that need
it there (misc/lookup, devel/flim, devel/semi).  The functional changes
made upstream since are kept.

--- mcharset.el.orig
+++ mcharset.el
@@ -1,4 +1,4 @@
-;;; mcharset.el --- MIME charset API  -*- lexical-binding: t -*-
+;;; mcharset.el --- MIME charset API
 
 ;; Copyright (C) 1997,1998,1999,2000 Free Software Foundation, Inc.
 
@@ -24,8 +24,17 @@
 
 ;;; Code:
 
+(require 'poe)
+(require 'pcustom)
+
+(if (featurep 'mule)
+    (require 'mcs-20)
+  (require 'mcs-ltn1))
+
 (defcustom default-mime-charset-for-write
-  'utf-8
+  (if (mime-charset-p 'utf-8)
+      'utf-8
+    default-mime-charset)
   "Default value of MIME-charset for encoding.
 It may be used when suitable MIME-charset is not found.
 It must be symbol."
@@ -39,13 +48,10 @@ It must be nil or function.
 If it is nil, variable `default-mime-charset-for-write' is used.
 If it is a function, interface must be (TYPE CHARSETS &rest ARGS).
 CHARSETS is list of charset.
-If TYPE is \\='region, ARGS has START and END."
+If TYPE is 'region, ARGS has START and END."
   :group 'i18n
   :type '(choice function (const nil)))
 
-(provide 'mcharset)
-(require 'mcs-20)
-
 (defun charsets-to-mime-charset (charsets)
   "Return MIME charset from list of charset CHARSETS.
 Return nil if suitable mime-charset is not found."
