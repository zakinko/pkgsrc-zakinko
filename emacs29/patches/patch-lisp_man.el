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

Whether pkgsrc is at fault is not settled.  A peer session ran od -c on
.PLIST-1src from the failing run: find(1)'s stderr, then about a kilobyte of
NUL, then an OutOfMemoryError from another session's JVM, and only then the
correct PLIST.  That box had 16GB of RAM against 256MB of swap, 95% full,
with a Java build alongside, and /var/log/messages recorded

	UVM: pid 5530 (bmake), uid 0 killed: out of swap

The same peer re-ran it once the box was quiet -- load 0.94, nothing else
building, no new "out of swap" during the run.  The NUL and the JVM text
were gone; find(1)'s stderr was still there, ahead of the @comment line the
PLIST starts with.  So memory pressure accounts for the NUL and the foreign
text but not for the stray stderr, and what writes a non-filename line into
that file is still unknown.  Those two runs are the peer's measurements; the
dd lines above are what was measured here.  The first attempt here died of
memory too (exit 137), so emacs was never reached either way.

Two DragonFly 6.4 boxes were tried and both stopped responding partway
through, the second while pkgsrc was still being unpacked.  155 packets over
45 minutes drew no reply and port 22 stayed closed.  Why is not known: the
OpenBSD box stayed up and kept its logs, but these went away entirely, so
there is nothing to read.  The second box was looked at before anything was
started -- 16GB of RAM and no swap configured at all -- and 16GB of swap was
added first; swap use was 0% when it went.  That rules out the OpenBSD
failure mode and names no other.

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
