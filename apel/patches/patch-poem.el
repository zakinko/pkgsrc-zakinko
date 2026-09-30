$NetBSD$

Restore what upstream removed on 2020-06-25 ("Drop old platforms support"),
so APEL still serves Emacs 20 and XEmacs; pkgsrc has packages that need
it there (misc/lookup, devel/flim, devel/semi).  The functional changes
made upstream since are kept.

--- poem.el.orig
+++ poem.el
@@ -1,4 +1,4 @@
-;;; poem.el --- Emulate latest MULE features  -*- lexical-binding: t -*-
+;;; poem.el --- Emulate latest MULE features; -*-byte-compile-dynamic: t;-*-
 
 ;; Copyright (C) 1998,1999 Free Software Foundation, Inc.
 
@@ -24,19 +24,56 @@
 
 ;;; Code:
 
-(require 'poem-e20)
+(require 'pces)
 
+(if (featurep 'mule)
+    (if (featurep 'xemacs)
+	(require 'poem-xm)
+      (require 'poem-e20))
+  (require 'poem-ltn1))
+
+
+;;; @ Emacs 20.3 emulation
+;;;
+
+(defsubst-maybe string-as-unibyte (string)
+  "Return a unibyte string with the same individual bytes as STRING.
+If STRING is unibyte, the result is STRING itself.
+\[Emacs 20.3 emulating macro]"
+  string)
+
+(defsubst-maybe string-as-multibyte (string)
+  "Return a multibyte string with the same individual bytes as STRING.
+If STRING is multibyte, the result is STRING itself.
+\[Emacs 20.3 emulating macro]"
+  string)
+
+(defun-maybe charset-after (&optional pos)
+  "Return charset of a character in current buffer at position POS.
+If POS is nil, it defaults to the current point.
+If POS is out of range, the value is nil.
+\[Emacs 20.3 emulating function]"
+  (char-charset (char-after pos))
+  )
 
 ;;; @ XEmacs-mule emulation
 ;;;
 
-(defalias 'char-int 'identity)
+(defalias-maybe 'char-int 'identity)
+
+(defalias-maybe 'int-char 'identity)
 
-(defalias 'int-char 'identity)
+(defalias-maybe 'characterp
+  (cond
+   ((fboundp 'char-valid-p) 'char-valid-p)
+   (t 'integerp)))
 
-(defalias 'char-or-char-int-p 'characterp)
+(defalias-maybe 'char-or-char-int-p
+  (cond
+   ((fboundp 'char-valid-p) 'char-valid-p)
+   (t 'integerp)))
 
-(defun char-octet (ch &optional n)
+(defun-maybe char-octet (ch &optional n)
   "Return the octet numbered N (should be 0 or 1) of char CH.
 N defaults to 0 if omitted. [XEmacs-mule emulating function]"
   (or (nth (if n
