$NetBSD$

Safe temporary-file infrastructure for Mule 2.3, in subr.el (loaded early,
so it is available to everything).  Three pieces:

  - make-temp-file: the race-free replacement for make-temp-name.  It creates
    the file itself with O_EXCL (via the raw subr si:write-region's `excl'
    argument, added in patch-foundation-write-region-excl) and retries on
    collision.  Ported from GNU Emacs cdd9f64394f26d60c2c0ffe99719f8df9586ed80
    (1999-09-11, "make-temp-file: New function").

  - temporary-file-directory: make-temp-file expands a relative prefix against
    it, and Mule lacked it -- so Mule also never honoured $TMPDIR.  Ported
    from cdda8f47bea08acb08e953f2c09211c3cfa9b7dd (1998-05-19).

  - mule-ensure-safe-dir / mule-user-temp-directory: a per-user 0700 directory
    with an ownership/no-symlink/no-loose-mode check, in which a fixed,
    predictable basename is safe.  Ported from GNU Emacs server-ensure-safe-dir
    (724629d2c2c); Mule uses it for ledit and medit, whose scratch files have
    fixed names dictated by the external programs they talk to and so cannot
    be randomised with make-temp-file.  The same private-directory idea is what
    upstream moved its server socket to (03ae35cf); Mule applies it in C for
    emacsserver too.

Deviations forced by Mule 2.3, unchanged from before:

  - temporary-file-directory and this helper live in subr.el, not files.el:
    touching files.el makes the build re-byte-compile files.elc, which aborts
    in this tree ("void: ange-ftp-completion-hook-function", ange-ftp not
    loaded during a -batch compile).

  - Mule redefines write-region in mule.el with a coding-system sixth
    argument, so make-temp-file calls the saved raw subr si:write-region,
    whose sixth argument is the MUSTBENEW added in the write-region patch.
    That subr never grew vanilla's LOCKNAME argument, so `excl' is its sixth
    argument, not the seventh.

Verified on NetBSD 9.4/i386 with the dumped binary and lisp/tests
(mule-sec-tests.el).
--- lisp/subr.el.orig	1995-01-01 00:00:00.000000000 +0000
+++ lisp/subr.el
@@ -829,5 +829,83 @@
 
 (or (fboundp 'skip-syntax-backward)
     (defalias 'skip-syntax-backward 'skip-syntax-backward-18))
+
+(defvar temporary-file-directory
+  (file-name-as-directory
+   (cond ((memq system-type '(ms-dos windows-nt))
+	  (or (getenv "TEMP") (getenv "TMPDIR") (getenv "TMP") "c:/temp"))
+	 ((memq system-type '(vax-vms axp-vms))
+	  (or (getenv "TMPDIR") (getenv "TMP") (getenv "TEMP") "SYS$SCRATCH:"))
+	 (t
+	  (or (getenv "TMPDIR") (getenv "TMP") (getenv "TEMP") "/tmp"))))
+  "The directory for writing temporary files.")
+
+(defun make-temp-file (prefix &optional dir-flag)
+  "Create a temporary file.
+The returned file name (created by appending some random characters at the end
+of PREFIX, and expanding against `temporary-file-directory' if necessary,
+is guaranteed to point to a newly created empty file.
+You can then use `write-region' to write new data into the file.
+
+If DIR-FLAG is non-nil, create a new empty directory instead of a file."
+  (let (file)
+    (while (condition-case ()
+	       (progn
+		 (setq file
+		       (make-temp-name
+			(expand-file-name prefix temporary-file-directory)))
+		 (if dir-flag
+		     (make-directory file)
+		   ;; Mule redefines write-region (mule.el) so that its sixth
+		   ;; argument is a coding-system, not MUSTBENEW.  Call the
+		   ;; saved raw subr si:write-region instead; its sixth
+		   ;; argument is the MUSTBENEW added in
+		   ;; patch-foundation-write-region-excl, so `excl' gives the
+		   ;; atomic O_EXCL create.  (Mule's write-region also has no
+		   ;; LOCKNAME argument, so MUSTBENEW is the sixth here, not
+		   ;; the seventh as in the Emacs original.)
+		   (si:write-region "" nil file nil 'silent 'excl))
+		 nil)
+	    (file-already-exists t))
+      ;; the file was somehow created by someone else between
+      ;; `make-temp-name' and `write-region', let's try again.
+      nil)
+    file))
 
+(defun mule-ensure-safe-dir (dir)
+  "Make sure DIR is a directory with no race-condition issues.
+Create it mode 0700 if it does not exist, then verify it is a real
+directory (not a symlink) owned by the current user with no group or other
+permission bits.  Return DIR as a directory file name, or signal an error
+if it is unsafe.
+
+A temporary file with a fixed, predictable basename is safe inside such a
+directory, because no other user can create an entry there and pre-empt it
+with a symbolic link.  This is how GNU Emacs's Lisp server keeps its socket
+safe (server-ensure-safe-dir, added in commit 724629d2c2c); Mule reuses the
+idea for the handful of features -- ledit, medit -- whose scratch files
+have fixed names it cannot randomise."
+  (setq dir (directory-file-name dir))
+  (let ((attrs (file-attributes dir)))
+    (or attrs
+	(let ((um (default-file-modes)))
+	  (unwind-protect
+	      (progn
+		(set-default-file-modes 448) ; 0700
+		(make-directory dir))
+	    (set-default-file-modes um))
+	  (setq attrs (file-attributes dir))))
+    (or (and (eq t (car attrs))		    ; a real directory, not a symlink
+	     (eq (nth 2 attrs) (user-uid))  ; owned by us
+	     (zerop (logand 63 (file-modes dir)))) ; 63 = 0077: no group/other
+	(error "The directory %s is unsafe" dir))
+    dir))
+
+(defun mule-user-temp-directory ()
+  "Return a per-user subdirectory of `temporary-file-directory', mode 0700.
+It is created and safety-checked with `mule-ensure-safe-dir'.  Fixed-name
+temporary files are safe inside the returned directory."
+  (mule-ensure-safe-dir
+   (expand-file-name (format "emacs%d" (user-uid)) temporary-file-directory)))
+
 ;;; subr.el ends here
