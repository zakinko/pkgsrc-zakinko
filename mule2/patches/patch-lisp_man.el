$NetBSD$

CVE-2025-1244: a man page reference that matches neither "chmod(2V)" nor
"2v chmod" was returned unchanged, and Man-getpage-in-background hands the
result to "sh -c" through Man-build-man-command.  So a reference containing
shell metacharacters ran them.  "ls; id" is enough.

Quote each whitespace-separated word instead of passing the string through.
That is what GNU Emacs 30.1 does (820f0793f0), except that its version calls
split-string, which 19.28 does not have; the loop here is the same thing
written with string-match.  Quoting the whole reference as one word would
have been shorter but would break "-k foo", which is a legitimate reference
and reaches this branch.

lisp/man.elc ships in the distribution and would shadow this, so man.el is
in the post-build recompile list in the package Makefile.

--- lisp/man.el.orig
+++ lisp/man.el
@@ -433,7 +433,20 @@
       (setq name (Man-match-substring 2 ref)
 	    section (Man-match-substring 1 ref))))
     (if (string= name "")
-	ref				; Return the reference as is
+	;; Not a "chmod(2V)" or "2v chmod" reference.  It used to be returned
+	;; as is, and Man-getpage-in-background hands the result to "sh -c",
+	;; so a reference like "ls; id" ran id.  Quote each whitespace-
+	;; separated word instead; that leaves "-k foo" style references
+	;; working.  Same answer as GNU Emacs 30.1 (820f0793f0), written
+	;; without split-string, which 19.28 does not have.
+	(let ((start 0) (words nil))
+	  (while (string-match "[^ \t\n]+" ref start)
+	    (setq words (cons (shell-quote-argument
+			       (substring ref (match-beginning 0)
+					  (match-end 0)))
+			      words)
+		  start (match-end 0)))
+	  (mapconcat 'identity (nreverse words) " "))
       (if Man-downcase-section-letters-flag
 	  (setq section (downcase section)))
       (while slist
