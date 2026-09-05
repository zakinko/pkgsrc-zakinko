$NetBSD$

Print each file as custom-deps scans it.

cus-dep.el runs under "emacs -batch" during the build and walks every .el in
lisp to build cus-load.el.  With this line the build log names the file it is
on; without it the step is silent for as long as it takes.

Why pkgsrc wanted that is not recorded, and nothing else here depends on the
output -- the message goes to stderr and no rule reads it.  It is kept because
removing it would change what the build prints for no gain, not because a
reason for it is known.

--- lisp/cus-dep.el.orig	2010-04-03 22:26:07.000000000 +0000
+++ lisp/cus-dep.el
@@ -59,6 +59,7 @@ Usage: emacs -batch -l ./cus-dep.el -f c
             (unless (or (string-match custom-dependencies-no-scan-regexp file)
                         (string-match preloaded file)
                         (not (file-exists-p file)))
+	      (message file)
               (erase-buffer)
               (insert-file-contents file)
               (goto-char (point-min))
