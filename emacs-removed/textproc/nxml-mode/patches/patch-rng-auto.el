$NetBSD$

Emacs 20: load nxml-e20.el for the functions Emacs 21 added, instead of
refusing to run.  The Mule-UCS check is dropped too: on Emacs 20 Mule-UCS
is where decode-char comes from.

--- rng-auto.el.orig
+++ rng-auto.el
@@ -22,12 +22,8 @@
 
 (setq nxml-version "20041004")
 
-(unless (and (fboundp 'make-hash-table)
-	     (boundp 'fontification-functions))
-  (error "FSF GNU Emacs version 21 or later required"))
+(if (< emacs-major-version 21) (require (quote nxml-e20)))
 
-(when (featurep 'mucs)
-  (error "nxml-mode is not compatible with Mule-UCS"))
 
 ;; Add fix for Unicode-display bug in Emacs 21.1 on Windows (fixed in 21.2)
 (when (and (fboundp 'w32-add-charset-info)
