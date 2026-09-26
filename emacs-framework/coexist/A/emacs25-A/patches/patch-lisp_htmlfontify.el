$NetBSD$

htmlfontify builds a shell command out of the file name it is given and runs
it through shell-command-to-string, so a name holding shell metacharacters
runs commands.  This is CVE-2022-48339, upstream commit

	807d2d5b3a  Fix htmlfontify.el command injection vulnerability.

on the emacs-28 branch, for the 28.3 release that was never made.  The one
line differs from 28.2 only in its surroundings.  See debbugs 60295.

--- lisp/htmlfontify.el.orig
+++ lisp/htmlfontify.el
@@ -1898,7 +1898,7 @@
 
 (defun hfy-text-p (srcdir file)
   "Is SRCDIR/FILE text?  Uses `hfy-istext-command' to determine this."
-  (let* ((cmd (format hfy-istext-command (expand-file-name file srcdir)))
+  (let* ((cmd (format hfy-istext-command (shell-quote-argument (expand-file-name file srcdir))))
          (rsp (shell-command-to-string    cmd)))
     (string-match "text" rsp)))
 
