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

reproducible after cleaning the obj tree here.

That box's /dev/null had been replaced by an ordinary file.  Once that is so
every `2>/dev/null' in a build appends to it instead of discarding, and

	_GENERATE_PLIST = ${CAT} /dev/null ${PLIST_SRC}   (mk/plist/plist.mk)

reads the accumulation back and puts it in front of the PLIST.  Whatever
wrote there last is what turns up -- dd's statistics from libtool here,
find(1)'s stderr in a peer session's run on the same box, once an
OutOfMemoryError from an unrelated JVM, and runs of NUL where two writers
used different offsets.  Measured here on a quiet box: the bad .PLIST-1src
was 1213 bytes, of which bytes 141 to 1213 are byte-identical to the
package's own 1073-byte PLIST, the first 140 being one find message.  A peer
session confirmed it under ktrace, watching cat read those bytes and write
them ahead of the PLIST, and repaired the box with

	cd /dev && sh MAKEDEV std

So this is not a pkgsrc bug, and not memory pressure either -- that was the
first answer here and it was wrong; the box was short of swap at the time,
which fitted and explained nothing.  If a PLIST ever carries lines that are
not filenames, look at `ls -l /dev/null' first.

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
