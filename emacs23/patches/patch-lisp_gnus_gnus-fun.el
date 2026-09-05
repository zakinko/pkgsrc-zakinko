$NetBSD$

gnus-grab-cam-face wrote the grabbed picture to /tmp/gnus.face.ppm, a name
anyone can predict and pre-create.  This is CVE-2014-3421.  Upstream took a
temporary file from make-temp-file instead; the result is what 24.5 ships, and
that is what is placed here.

The patch that stood here before did not do that.  It put

	(tempfile (make-temp-file "gnus-face-" nil ".ppm"))

in the body of the let rather than in its bindings, so it read as a call to a
function named tempfile that does not exist, and the tempfile referred to
below was never bound.  Byte-compiling the function alone says so:

	Warning: reference to free variable 'tempfile'
	Warning: the function 'tempfile' is not known to be defined.

gnus-grab-cam-face would have stopped with void-function tempfile before
reaching any of this, so the temporary file was never created and the fix was
not in effect.  The same patch had also broken the shell command in two by
putting a newline inside the format string, between "pnmscale" and its
"-width" argument.  Neither is upstream's; both are gone.

--- lisp/gnus/gnus-fun.el.orig
+++ lisp/gnus/gnus-fun.el
@@ -260,20 +260,21 @@
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
