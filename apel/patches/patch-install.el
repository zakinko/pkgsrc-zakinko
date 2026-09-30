$NetBSD$

Restore what upstream removed on 2020-06-25 ("Drop old platforms support"),
so APEL still serves Emacs 20 and XEmacs; pkgsrc has packages that need
it there (misc/lookup, devel/flim, devel/semi).  The functional changes
made upstream since are kept.

--- install.el.orig
+++ install.el
@@ -1,4 +1,4 @@
-;;; install.el --- Emacs Lisp package install utility  -*- lexical-binding: t -*-
+;;; install.el --- Emacs Lisp package install utility
 
 ;; Copyright (C) 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2006
 ;; 	Free Software Foundation, Inc.
@@ -26,6 +26,7 @@
 
 ;;; Code:
 
+(require 'poe)				; make-directory for v18
 (require 'path-util)			; default-load-path
 
 
@@ -42,8 +43,9 @@
 
 (defun compile-elisp-modules (modules &optional path every-time)
   (mapcar
-   (lambda (module)
-     (compile-elisp-module module path every-time))
+   (function
+    (lambda (module)
+      (compile-elisp-module module path every-time)))
    modules))
 
 
@@ -78,8 +80,9 @@
       (file-exists-p dest)
       (make-directory dest t))
   (mapcar
-   (lambda (file)
-     (install-file file src dest move overwrite just-print))
+   (function
+    (lambda (file)
+      (install-file file src dest move overwrite just-print)))
    files))
 
 
@@ -131,8 +134,9 @@
       (file-exists-p dest)
       (make-directory dest t))
   (mapcar
-   (lambda (module)
-     (install-elisp-module module src dest just-print del-elc))
+   (function
+    (lambda (module)
+      (install-elisp-module module src dest just-print del-elc)))
    modules))
 
 
@@ -141,12 +145,17 @@
 
 ;; install to shared directory (maybe "/usr/local")
 (defvar install-prefix
-  (if (and (eq system-type 'windows-nt) ; for NTEmacs
-	   ;; Exclude the case that built by running the same
-	   ;; configure script as on all other platforms.
-	   (equal (file-name-nondirectory
-		   (expand-file-name "." exec-directory))
-		  "bin"))
+  (if (or (<= emacs-major-version 18)
+	  (featurep 'xemacs)
+	  (featurep 'meadow) ; for Meadow
+	  (and (eq system-type 'windows-nt) ; for NTEmacs
+	       (>= emacs-major-version 20)
+	       ;; Exclude the case that built by running the same
+	       ;; configure script as on all other platforms.
+	       (equal (file-name-nondirectory
+		       (expand-file-name "." exec-directory))
+		      "bin")
+	       ))
       (expand-file-name "../../.." exec-directory)
     (expand-file-name "../../../.." data-directory)))
 
@@ -165,14 +174,27 @@
 	(let ((rest (delq nil (copy-sequence default-load-path)))
 	      (regexp
 	       (concat "^"
-		       (regexp-quote (file-name-as-directory
-				      (expand-file-name prefix)))
+		       (regexp-quote (if (featurep 'xemacs)
+					 ;; Handle backslashes (Windows)
+					 (replace-in-string
+					  (file-name-as-directory
+					   (expand-file-name prefix))
+					  "\\\\" "/")
+				       (file-name-as-directory
+					(expand-file-name prefix))))
 		       ".*/"
-		       (regexp-quote elisp-prefix)
+		       (regexp-quote
+			(if (featurep 'xemacs)
+			    ;; Handle backslashes (Windows)
+			    (replace-in-string elisp-prefix "\\\\" "/")
+			  elisp-prefix))
 		       "/?$"))
 	      dir)
 	  (while rest
-	    (setq dir (car rest))
+	    (setq dir (if (featurep 'xemacs)
+			  ;; Handle backslashes (Windows)
+			  (replace-in-string (car rest) "\\\\" "/")
+			(car rest)))
 	    (if (string-match regexp dir)
 		(if (or allow-version-specific
 			(not (string-match (format "/%d\\.%d"
@@ -181,7 +203,15 @@
 					   dir)))
 		    (throw 'tag (car rest))))
 	    (setq rest (cdr rest)))))
-      (expand-file-name (concat "share/emacs/" elisp-prefix)
+      (expand-file-name (concat (if (featurep 'xemacs)
+				    "lib/"
+				  "share/")
+				(if (featurep 'xemacs)
+				    (if (featurep 'mule)
+					"xmule/"
+				      "xemacs/")
+				  "emacs/")
+				elisp-prefix)
 			prefix)))
 
 (defvar install-default-elisp-directory
@@ -192,12 +222,62 @@
 ;;;
 
 (defun install-get-default-package-directory ()
-  ;; Dummy function.  Do nothing.
-  nil)
-
-(defun install-update-package-files (_package _dir &optional _just-print)
-  ;; Dummy function.  Do nothing.
-  nil)
+  (let ((dirs (append
+	       (cond
+		((boundp 'early-package-hierarchies)
+		 (append (if early-package-load-path
+			     early-package-hierarchies)
+			 (if late-package-load-path
+			     late-package-hierarchies)
+			 (if last-package-load-path
+			     last-package-hierarchies)) )
+		((boundp 'early-packages)
+		 (append (if early-package-load-path
+			     early-packages)
+			 (if late-package-load-path
+			     late-packages)
+			 (if last-package-load-path
+			     last-packages)) ))
+	       (if (and (boundp 'configure-package-path)
+			(listp configure-package-path))
+		   (delete "" configure-package-path))))
+	dir)
+    (while (and (setq dir (car dirs))
+		(not (file-exists-p dir)))
+      (setq dirs (cdr dirs)))
+    dir))
+
+(defun install-update-package-files (package dir &optional just-print)
+  (cond
+   (just-print
+    (princ (format "Updating autoloads in directory %s..\n\n" dir))
+
+    (princ (format "Processing %s\n" dir))
+    (princ "Generating custom-load.el...\n\n")
+
+    (princ (format "Compiling %s...\n"
+		   (expand-file-name "auto-autoloads.el" dir)))
+    (princ (format "Wrote %s\n"
+		   (expand-file-name "auto-autoloads.elc" dir)))
+
+    (princ (format "Compiling %s...\n"
+		   (expand-file-name "custom-load.el" dir)))
+    (princ (format "Wrote %s\n"
+		   (expand-file-name "custom-load.elc" dir))))
+   (t
+    (if (fboundp 'batch-update-directory-autoloads)
+	;; XEmacs 21.5.19 and newer.
+	(let ((command-line-args-left (list package dir)))
+	  (batch-update-directory-autoloads))
+      (setq autoload-package-name package)
+      (let ((command-line-args-left (list dir)))
+	(batch-update-directory)))
+
+    (let ((command-line-args-left (list dir)))
+      (Custom-make-dependencies))
+
+    (byte-compile-file (expand-file-name "auto-autoloads.el" dir))
+    (byte-compile-file (expand-file-name "custom-load.el" dir)))))
 
 
 ;;; @ Other Utilities
