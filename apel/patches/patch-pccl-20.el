$NetBSD$

Restore what upstream removed on 2020-06-25 ("Drop old platforms support"),
so APEL still serves Emacs 20 and XEmacs; pkgsrc has packages that need
it there (misc/lookup, devel/flim, devel/semi).  The functional changes
made upstream since are kept; here make-coding-system, gone from
Emacs 30, is used only where define-coding-system does not exist.

--- pccl-20.el.orig
+++ pccl-20.el
@@ -1,4 +1,4 @@
-;;; pccl-20.el --- Portable CCL utility for Emacs 20 and XEmacs-21-mule  -*- lexical-binding: t -*-
+;;; pccl-20.el --- Portable CCL utility for Emacs 20 and XEmacs-21-mule
 
 ;; Copyright (C) 1998 Free Software Foundation, Inc.
 ;; Copyright (C) 1998 Tanaka Akira
@@ -34,25 +34,69 @@
     (define-ccl-program test-ccl-identity
       '(1 ((read r0) (loop (write-read-repeat r0)))))
     (condition-case nil
-        (ccl-execute-on-string
-	 'test-ccl-identity (make-vector 9 nil) "")
+        (progn
+          (funcall
+	   (if (fboundp 'ccl-vector-execute-on-string)
+	       'ccl-vector-execute-on-string
+	     'ccl-execute-on-string)
+           'test-ccl-identity
+           (make-vector 9 nil)
+           "")
+          t)
       (error nil)))
   t)
 
 (eval-and-compile
 
-  (defun make-ccl-coding-system
+  (static-if (featurep 'xemacs)
+      (defadvice make-coding-system (before ccl-compat (name type &rest ad-subr-args) activate)
+	(when (and (integerp type)
+		   (eq type 4)
+		   (characterp (ad-get-arg 2))
+		   (stringp (ad-get-arg 3))
+		   (consp (ad-get-arg 4))
+		   (symbolp (car (ad-get-arg 4)))
+		   (symbolp (cdr (ad-get-arg 4))))
+	  (setq type 'ccl)
+	  (setq ad-subr-args
+		(list
+		 (ad-get-arg 3)
+		 (append
+		  (list
+		   'mnemonic (char-to-string (ad-get-arg 2))
+		   'decode (symbol-value (car (ad-get-arg 4)))
+		   'encode (symbol-value (cdr (ad-get-arg 4))))
+		  (ad-get-arg 5)))))))
+
+  (if (featurep 'xemacs)
+      (defun make-ccl-coding-system (name mnemonic docstring decoder encoder)
+	"\
+Define a new CODING-SYSTEM by CCL programs DECODER and ENCODER.
+
+CODING-SYSTEM, DECODER and ENCODER must be symbol."
+	(make-coding-system
+	 name 'ccl docstring
+	 (list 'mnemonic (char-to-string mnemonic)
+	       'decode (symbol-value decoder)
+	       'encode (symbol-value encoder))))
+    (defun make-ccl-coding-system
       (coding-system mnemonic docstring decoder encoder)
-    "\
+      "\
 Define a new CODING-SYSTEM by CCL programs DECODER and ENCODER.
 
 CODING-SYSTEM, DECODER and ENCODER must be symbol."
-    (when-broken ccl-accept-symbol-as-program
-      (setq decoder (symbol-value decoder))
-      (setq encoder (symbol-value encoder)))
-    (define-coding-system coding-system docstring
-      :mnemonic mnemonic :coding-type 'ccl
-      :ccl-decoder decoder :ccl-encoder encoder))
+      (when-broken ccl-accept-symbol-as-program
+	(setq decoder (symbol-value decoder))
+	(setq encoder (symbol-value encoder)))
+      ;; make-coding-system is gone from Emacs 30; define-coding-system
+      ;; exists since 23.
+      (if (fboundp 'define-coding-system)
+	  (define-coding-system coding-system docstring
+	    :mnemonic mnemonic :coding-type 'ccl
+	    :ccl-decoder decoder :ccl-encoder encoder)
+	(make-coding-system coding-system 4 mnemonic docstring
+			    (cons decoder encoder))))
+    )
 
   (when-broken ccl-accept-symbol-as-program
 
