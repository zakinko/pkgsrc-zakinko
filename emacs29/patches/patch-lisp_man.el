$NetBSD$

Man-getpage-in-background runs the man command under sh -c and formats the
page name into it, so whatever Man-translate-references returns reaches a
shell.  A reference with no section part is returned unchanged, and
"M-x man RET ;id RET" therefore runs id.  This is CVE-2025-1244, upstream
commit

	820f0793f0  Fix man.el shell injection vulnerability

which was released only in 30.1, so 29.4 does not have it.  See debbugs
66390.

Measured on four platforms.  On each, the built emacs was asked for
Man-translate-references ";id", against a control run that loaded the
unpatched 29.4 man.el into the same binary:

	NetBSD 11.0/amd64         "\\;id"   control ";id"
	FreeBSD 15.1-RELEASE-p3   "\\;id"   control ";id"
	GhostBSD 26.1 (FreeBSD 15.0-RELEASE-p10)
	                          "\\;id"   control ";id"
	OpenBSD 7.9/amd64         "\\;id"   control ";id"

man.elc carries shell-quote-argument in all four, so the patch is in the byte
code that actually runs and not only in the source.  Man-build-man-command is
not a useful check on this branch: 29.4 returns a template with %s where the
page name goes, the same string on both sides, and substitutes the name later
in Man-getpage-in-background.

The first attempts on OpenBSD stopped in a dependency, well before emacs, with
pkg_create handed a file list whose first lines were dd(1)'s statistics rather
than filenames.  That box's /dev/null had been replaced by an ordinary file,
so every `2>/dev/null' in the build appended to it instead of discarding, and
mk/plist/plist.mk's

	_GENERATE_PLIST = ${CAT} /dev/null ${PLIST_SRC}

read the accumulation back and put it in front of the PLIST -- dd's statistics
from libtool here, find(1)'s stderr in a peer session's run on the same box.
After `cd /dev && sh MAKEDEV std' the same tree built emacs29-nox11 and its
twenty-odd dependencies without incident, which is where the OpenBSD row comes
from.  Not a pkgsrc bug, and not the memory pressure it was first put down to.
If a PLIST ever carries lines that are not filenames, look at `ls -l /dev/null'
first.

Not measured: DragonFly 6.4.  Two boxes were tried and both stopped responding
partway through, the second while pkgsrc was still being unpacked; 155 packets
over 45 minutes drew no reply and port 22 stayed closed.  Why is not known --
unlike the OpenBSD box, which stayed up and kept its logs, these went away
entirely.  The second was looked at before anything was started, had 16GB of
RAM and no swap configured at all, and was given 16GB of swap first; swap use
was 0% when it went.

This header has been rewritten several times while the OpenBSD failure was
being diagnosed, so the file's checksum is no longer the one the first three
rows were measured against.  The patch body below is unchanged throughout --
one line removed and five added, at lisp/man.el:684.

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
