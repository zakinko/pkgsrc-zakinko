$NetBSD$

Man-getpage-in-background runs the man command under sh -c and formats the
page name into it, so whatever Man-translate-references returns reaches a
shell.  A reference with no section part is returned unchanged, and
"M-x man RET ;id RET" therefore runs id.  This is CVE-2025-1244, upstream
commit

	820f0793f0  Fix man.el shell injection vulnerability

which was released only in 30.1, so 29.4 does not have it.  See debbugs
66390.

Measured on three platforms.  On each, the built emacs was asked for
Man-translate-references ";id", against a control run that loaded the
unpatched 29.4 man.el into the same binary:

	NetBSD 11.0/amd64         "\\;id"   control ";id"
	FreeBSD 15.1-RELEASE-p3   "\\;id"   control ";id"
	GhostBSD 26.1 (FreeBSD 15.0-RELEASE-p10)
	                          "\\;id"   control ";id"

and the command that reaches sh -c became "man  \\;id 2>" where it had been
"man  ;id 2>/".  man.elc carries shell-quote-argument in all three, so the
patch is in the byte code that actually runs, not only in the source.

Not measured: OpenBSD 7.9 and DragonFly 6.4.  On OpenBSD the dependency
archivers/bzip2 cannot be packaged -- pkgsrc's generated PLIST picks up
dd(1)'s stderr ("1+0 records in") as if those were file names -- so the
build never reaches emacs.  The DragonFly box became unreachable partway
through and did not come back.

--- lisp/man.el.orig
+++ lisp/man.el
@@ -684,7 +684,11 @@
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
