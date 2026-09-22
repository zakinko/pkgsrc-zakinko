$NetBSD$

Old-style backquote, which Emacs stopped reading in 24.  From Gentoo.

--- xrdb-mode.el.orig
+++ xrdb-mode.el
@@ -178,9 +178,9 @@
 
 (defmacro xrdb-safe (&rest body)
   "Safely execute BODY, return nil if an error occurred."
-  (` (condition-case nil
-         (progn (,@ body))
-       (error nil))))
+  `(condition-case nil
+       (progn ,@ body)
+     (error nil)))
 
 (defsubst xrdb-skip-to-separator ()
   "Skip forward.
