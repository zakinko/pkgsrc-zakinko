$NetBSD$

string-to-int is gone in modern Emacs; string-to-number has been there all
along.  This one is reached when a repeat count is typed.

--- egg-mlh.el.orig
+++ egg-mlh.el
@@ -122,7 +122,7 @@
   (goto-char end-marker)
   (backward-delete-char 2)
   (let* ((str (buffer-substring beg (point)))
-         (val (string-to-int str)))
+         (val (string-to-number str)))
     (delete-region beg (point))
     (if (= val 0)
         (setq val 1))
@@ -220,7 +220,7 @@
   (goto-char end-marker)
   (backward-delete-char 2)
   (let* ((str (buffer-substring beg (point)))
-         (val (string-to-int str)))
+         (val (string-to-number str)))
     (delete-region beg (point))
     (if (= val 0)
         (setq val 1))
