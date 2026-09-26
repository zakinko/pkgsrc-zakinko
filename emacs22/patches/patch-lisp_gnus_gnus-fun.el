$NetBSD$

gnus-grab-cam-face writes the grabbed picture to /tmp/gnus.face.ppm, a name
anyone can predict and pre-create.  This is CVE-2014-3421.  Upstream takes a
temporary file from make-temp-file instead; the result is what 24.5 ships, and
that is what is placed here.

editors/emacs23 has the same change.  Do not copy the shape of the patch that
used to stand there: it put the make-temp-file binding in the body of the let
rather than in its bindings, which reads as a call to a function named
tempfile that does not exist.

--- lisp/gnus/gnus-fun.el.orig
+++ lisp/gnus/gnus-fun.el
@@ -227,20 +227,21 @@
   (interactive)
   (shell-command "xawtv-remote snap ppm")
   (let ((file nil)
+	(tempfile (make-temp-file "gnus-face-" nil ".ppm"))
 	result)
     (while (null (setq file (directory-files "/tftpboot/sparky/tmp"
 					     t "snap.*ppm")))
       (sleep-for 1))
     (setq file (car file))
     (shell-command
-     (format "pnmcut -left 110 -top 30 -width 144 -height 144 '%s' | pnmscale -width 48 -height 48 | ppmtopgm > /tmp/gnus.face.ppm"
-	     file))
+     (format "pnmcut -left 110 -top 30 -width 144 -height 144 '%s' | pnmscale -width 48 -height 48 | ppmtopgm >> %s"
+	     file tempfile))
     (let ((gnus-convert-image-to-face-command
 	   (format "cat '%%s' | ppmquant %%d | ppmchange %s | pnmtopng"
 		   (gnus-fun-ppm-change-string))))
-      (setq result (gnus-face-from-file "/tmp/gnus.face.ppm")))
+      (setq result (gnus-face-from-file tempfile)))
     (delete-file file)
-    ;;(delete-file "/tmp/gnus.face.ppm")
+    ;;(delete-file tempfile)    ; FIXME why are we not deleting it?!
     result))
 
 (defun gnus-fun-ppm-change-string ()
