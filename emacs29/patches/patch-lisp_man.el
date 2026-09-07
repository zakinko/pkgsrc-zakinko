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
archivers/bzip2 cannot be packaged, so the build never reaches emacs.  What
was seen is that pkg_create was handed a file list containing three lines
that are dd(1)'s statistics output:

	pkg_create: can't stat `.../pkg/1+0 records in'
	pkg_create: can't stat `.../pkg/1+0 records out'
	pkg_create: can't stat `.../pkg/4096 bytes transferred in 0.000 secs (...)'

reproducible after cleaning the obj tree here.  What runs dd was not
determined; pkgsrc's own mk/ has no dd on the paths that build the list.

This is not a pkgsrc bug.  A peer session reproduced the same shape on that
box and settled it: od -c on .PLIST-1src showed find(1)'s stderr, then about
a kilobyte of NUL, then an OutOfMemoryError from another session's JVM, and
only then the correct PLIST.  A shell pipeline does not produce runs of NUL,
so nothing in mk/plist wrote that file.  The box's /var/log/messages had

	UVM: pid 5530 (bmake), uid 0 killed: out of swap

with 16GB of RAM against 256MB of swap, 95% full, while a Java build ran
alongside.  The lines are what an OOM-killed process left half-written, not
anything pkgsrc emitted.  The first attempt here died the same way (exit
137).  So emacs was never reached, for want of memory on a shared machine --
if the same wall turns up again, look at /var/log/messages and the swap size
before suspecting the package.

The DragonFly box became unreachable partway through and did not come back.

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
