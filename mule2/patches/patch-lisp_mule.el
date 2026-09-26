$NetBSD$

Item 2: Mule's call-process-region (rewritten in Emacs Lisp -- the C
Fcall_process_region in callproc.c is #if 0'd out) picks its scratch file
with (make-temp-name "/tmp/emacs") and then write-region's the region to it.
make-temp-name only chooses a name that does not yet exist; between that and
the write, another local user can plant a symlink at the predictable name and
the write follows it.  This is the same make-temp-name race the Emacs project
answered by moving callers to make-temp-file.

Use make-temp-file (added in patch-foundation-make-temp-file, ported from GNU
Emacs cdd9f64394f26d60c2c0ffe99719f8df9586ed80): it creates the file itself
with O_EXCL and retries on collision, so the name handed back is one we
already own and the following write-region cannot be redirected.

The ms-dos arm is left as-is: it is a dead branch on this platform (system-type
is never ms-dos) and builds its own path from TMP/TEMP.
--- lisp/mule.el.orig	1995-01-01 00:00:00.000000000 +0000
+++ lisp/mule.el
@@ -1115,7 +1115,12 @@
 		     (concat tem
 			     (if (or (eq temm ?/) (eq temm ?\\)) "" "/")
 			     "em")))
-		(make-temp-name "/tmp/emacs")))
+		;; make-temp-name only picks an unused name; another user can
+		;; win the race and pre-plant a symlink at it before the
+		;; write-region below, which then writes through the link.
+		;; make-temp-file creates the file itself with O_EXCL, so the
+		;; name it returns is one we already own.
+		(make-temp-file "/tmp/emacs")))
 	(coding-systems (if call-process-hook
 			    (apply call-process-hook
 				   program buffer start end args)
