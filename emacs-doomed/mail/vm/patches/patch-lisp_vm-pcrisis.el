$NetBSD: patch-lisp_vm-pcrisis.el,v 1.1 2018/11/29 00:36:23 markd Exp $

remove  spurious &optional

make-face takes one argument in GNU Emacs; the second, a doc string, is
XEmacs only and loading vm-pcrisis failed with wrong-number-of-arguments.

--- lisp/vm-pcrisis.el.orig
+++ lisp/vm-pcrisis.el
@@ -225,15 +225,13 @@
 
 (make-variable-buffer-local 'vmpc-sig-exerlay)
 
-(defvar vmpc-pre-sig-face (progn (make-face 'vmpc-pre-sig-face
-	    "Face used for highlighting the pre-signature.")
+(defvar vmpc-pre-sig-face (progn (make-face 'vmpc-pre-sig-face)
 				 (set-face-foreground
 				  'vmpc-pre-sig-face "forestgreen")
 				 'vmpc-pre-sig-face)
   "Face used for highlighting the pre-signature.")
 
-(defvar vmpc-sig-face (progn (make-face 'vmpc-sig-face
-		"Face used for highlighting the signature.")
+(defvar vmpc-sig-face (progn (make-face 'vmpc-sig-face)
 			     (set-face-foreground 'vmpc-sig-face
 						  "steelblue")
 			     'vmpc-sig-face)
@@ -1214,7 +1212,7 @@
 ;; Functions for vmpc-conditions:
 ;; -------------------------------------------------------------------
 
-(defun vmpc-none-true-yet (&optional &rest exceptions)
+(defun vmpc-none-true-yet (&rest exceptions)
   "True if none of the previous evaluated conditions was true.
 This is a condition that can appear in `vmpc-conditions'.  If EXCEPTIONS are
 specified, it means none were true except those.  For example, if you wanted
