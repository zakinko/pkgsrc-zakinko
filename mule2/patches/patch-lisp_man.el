$NetBSD$

CVE-2025-1244: a man page reference that is not of the form "chmod(2V)" was
returned unchanged, and Man-getpage-in-background hands the result to "sh -c"
through Man-build-man-command.  So a reference containing shell metacharacters
ran them.  ";id" is enough.

Quote each whitespace-separated word instead of passing the string through.
That is what GNU Emacs 30.1 does (820f0793f0), except that its version calls
split-string, which 19.28 does not have; the loop here is the same thing
written with string-match.  Quoting the whole reference as one word would have
been shorter but would break "-k foo", which is a legitimate reference and
reaches this branch.

lisp/man.elc ships in the distribution and would shadow this, so man.el is in
the post-build recompile list in the package Makefile, and verify-mule2.sh
measures the result in the built mule rather than in the source.

--- lisp/man.el.orig
+++ lisp/man.el
@@ -335,7 +335,17 @@
 			      s2)
 		    slist nil))))
 	(concat Man-specified-section-option section " " word))
-    ref))
+    ;; A reference not of the form "chmod(2V)" used to be returned as
+    ;; is, and Man-getpage-in-background hands the result to "sh -c",
+    ;; so ";id" ran id.  Quote each whitespace-separated word; quoting
+    ;; the whole reference as one word would break "-k foo".
+    (let ((start 0) (words nil))
+      (while (string-match "[^ \t\n]+" ref start)
+	(setq words (cons (shell-quote-argument
+			   (substring ref (match-beginning 0) (match-end 0)))
+			  words)
+	      start (match-end 0)))
+      (mapconcat 'identity (nreverse words) " "))))
 
 (defun Man-linepos (&optional position col-p)
   "Return the character position at various line/buffer positions.
