$NetBSD$

CVE-2017-1000383: copy-file creates the backup with the default modes and
only then copies the original file's modes over it, so the backup of a
private file is world-readable until that chmod.  Create it under a
0700 umask; the chmod that follows still sets the final modes.  Same
fix as Emacs 25.3's backup-buffer-copy, in Emacs 20's files.el.

--- lisp/files.el.orig
+++ lisp/files.el
@@ -1996,7 +1996,16 @@
 			    (or delete-old-versions
 				(y-or-n-p (format "Delete excess backup versions of %s? "
 						  real-file-name))))))
-		  ;; Actually write the back up file.
+		  ;; Actually write the back up file.  copy-file creates
+		  ;; it with the default modes and only then copies the
+		  ;; original's, so a private file's backup is readable
+		  ;; by anyone until that chmod (CVE-2017-1000383).
+		  ;; Create it under a strict umask; copy-file's chmod
+		  ;; sets the final modes.
+		  (let ((umask (default-file-modes)))
+		    (unwind-protect
+			(progn
+			  (set-default-file-modes ?\700)
 		  (condition-case ()
 		      (if (or file-precious-flag
     ;			  (file-symlink-p buffer-file-name)
@@ -2035,7 +2044,8 @@
 			(if (and (file-exists-p backupname)
 				 (not (file-writable-p backupname)))
 			    (delete-file backupname))
-			(copy-file real-file-name backupname t t)))))
+			(copy-file real-file-name backupname t t))))))
+		      (set-default-file-modes umask)))
 		  (setq buffer-backed-up t)
 		  ;; Now delete the old versions, if desired.
 		  (if delete-old-versions
