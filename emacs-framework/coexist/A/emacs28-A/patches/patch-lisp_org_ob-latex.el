$NetBSD$

org-babel-execute:latex moves its output into place by handing "mv %s %s" to
a shell with the two file names formatted in, so a source block whose :file
argument -- or whose directory -- contains shell metacharacters runs commands
when the block is evaluated.  This is CVE-2023-28617.

Org fixed it in 9.6.2 by using rename-file instead of mv; the change reached
emacs.git as part of

	829e5dfabe  Update to Org 9.6.1-48-g92471e

for 29.1.  One of the call sites was doubly wrong: shell-command takes no
format arguments, so it ran the literal string "mv %s %s".

Not changed, because upstream has not changed it either as of 31.1: the
htlatex invocation a few lines above still formats tex-file into a shell
command without quoting.

--- lisp/org/ob-latex.el.orig
+++ lisp/org/ob-latex.el
@@ -167,7 +167,7 @@
 	                     tmp-pdf
                              (list org-babel-latex-pdf-svg-process)
                              extension err-msg log-buf)))
-              (shell-command (format "mv %s %s" img-out out-file)))))
+              (rename-file img-out out-file t))))
          ((string-suffix-p ".tikz" out-file)
 	  (when (file-exists-p out-file) (delete-file out-file))
 	  (with-temp-file out-file
@@ -205,17 +205,14 @@
 	    (if (string-suffix-p ".svg" out-file)
 		(progn
 		  (shell-command "pwd")
-		  (shell-command (format "mv %s %s"
-					 (concat (file-name-sans-extension tex-file) "-1.svg")
-					 out-file)))
+                  (rename-file (concat (file-name-sans-extension tex-file) "-1.svg")
+                               out-file t))
 	      (error "SVG file produced but HTML file requested")))
 	   ((file-exists-p (concat (file-name-sans-extension tex-file) ".html"))
 	    (if (string-suffix-p ".html" out-file)
-		(shell-command "mv %s %s"
-			       (concat (file-name-sans-extension tex-file)
-				       ".html")
-			       out-file)
-	      (error "HTML file produced but SVG file requested")))))
+                (rename-file (concat (file-name-sans-extension tex-file) ".html")
+                             out-file t)
+              (error "HTML file produced but SVG file requested")))))
 	 ((or (string= "pdf" extension) imagemagick)
 	  (with-temp-file tex-file
 	    (require 'ox-latex)
