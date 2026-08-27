$NetBSD$

Item 4: mailpost.el wrote its outgoing message to the fixed name /tmp/,rpost
(passed through make-temp-name, so a predictable name with a random suffix,
but still make-temp-name -- only chosen, not created).  Expand it against
temporary-file-directory (upstream 46595270d80, 1999-08-28) and create it
atomically with make-temp-file (from patch-foundation-make-temp-file, ported
from GNU Emacs cdd9f64), so no symlink can be pre-planted at the name.

--- lisp/mailpost.el.orig	1995-01-01 00:00:00.000000000 +0000
+++ lisp/mailpost.el
@@ -28,7 +28,7 @@
   (let ((errbuf (if mail-interactive
 		    (generate-new-buffer " post-mail errors")
 		  0))
-	(temfile "/tmp/,rpost")
+	(temfile (expand-file-name ",rpost" temporary-file-directory))
 	(tembuf (generate-new-buffer " post-mail temp"))
 	(case-fold-search nil)
 	delimline
@@ -77,7 +77,10 @@
 		(save-excursion
 		  (set-buffer errbuf)
 		  (erase-buffer))))
-	  (write-file (setq temfile (make-temp-name temfile)))
+	  ;; make-temp-file, not make-temp-name: create the scratch file
+	  ;; atomically with O_EXCL so a pre-planted symlink cannot redirect
+	  ;; the write below.  (write-file then overwrites our own file.)
+	  (write-file (setq temfile (make-temp-file temfile)))
 	  (set-file-modes temfile 384)
 	  (apply 'call-process
 		 (append (list (if (boundp 'post-mail-program)
