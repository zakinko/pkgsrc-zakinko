$NetBSD$

Man-getpage-in-background runs the man command under sh -c and formats the
page name into it, so whatever Man-translate-references returns reaches a
shell.  A reference with no section part is returned unchanged by the branch
below, and "M-x man RET ;id RET" therefore runs id.  Anything that calls man
with a name it did not choose -- a man: link in a buffer, an Info cross
reference -- hands that shell its argument.  This is CVE-2025-1244, upstream
commit

	820f0793f0  Fix man.el shell injection vulnerability

released in 30.1.  See debbugs 66390.

22.3 through 28.2 all carry these lines unchanged, so every one of those
packages gets this same hunk.

--- lisp/man.el.orig
+++ lisp/man.el
@@ -688,7 +688,11 @@
       (setq name (match-string 2 ref)
 	    section (match-string 1 ref))))
     (if (string= name "")
-	ref				; Return the reference as is
+        ;; see Bug#66390
+	(mapconcat 'identity
+                   (mapcar #'shell-quote-argument
+                           (split-string ref "\\s-+"))
+                   " ")                 ; Return the reference as is
       (if Man-downcase-section-letters-flag
 	  (setq section (downcase section)))
       (while slist
