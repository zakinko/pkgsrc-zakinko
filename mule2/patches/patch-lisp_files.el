$NetBSD$

Item 5: when saving a buffer whose file is read-only (the user answered yes to
"save anyway?"), basic-save-buffer-1 made the file writable by setting its
mode to 511 (0777) for the duration of the write -- briefly world-writable --
then restored the old mode.  Only the owner needs write permission; add 128
(0200) to the current mode instead, closing the window.

Verbatim port of GNU Emacs 4ff53720257ea847cbaa221e86e0956063d0b547
(2000-06-23, "(basic-save-buffer-2): When temporarily setting file modes, set
them to current modes plus 0200, not to 0777").  Mule's function is called
basic-save-buffer-1 but the line is identical.
--- lisp/files.el.orig	1995-01-01 00:00:00.000000000 +0000
+++ lisp/files.el
@@ -1701,7 +1701,10 @@
 	(cond ((and tempsetmodes (not setmodes))
 	       ;; Change the mode back, after writing.
 	       (setq setmodes (file-modes buffer-file-name))
-	       (set-file-modes buffer-file-name 511)))
+	       ;; 511 (0777) made the file world-writable for the duration of
+	       ;; the write; we only need write permission for ourselves.  Add
+	       ;; 128 (0200) to the current modes instead.
+	       (set-file-modes buffer-file-name (logior setmodes 128))))
 	(write-region (point-min) (point-max)
 		      buffer-file-name nil t)))
     setmodes))
