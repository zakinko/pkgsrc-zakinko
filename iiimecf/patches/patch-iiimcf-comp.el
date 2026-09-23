$NetBSD$

The lisp only wants un-define, a Mule-UCS file, for the UTF-16 coding systems,
and Emacs 22 and later have those of their own; see patch-lisp_EIMIL.el.  This
driver still refuses to go on without it, and the way it asks is fatal in a
batch build:

	(while (null (locate-library "un-define"))
	  ...
	  (setq path (read-from-minibuffer "")))

read-from-minibuffer reads stdin, stdin is at end of file, and the loop never
ends.  The build stops with "End of file during parsing: Error reading from
stdin" and exit code 255.

editors/mule-ucs/buildlink3.mk guards itself with EMACS_VERSION_MAJOR < 22, so
from emacs22 on the dependency is empty and un-define is simply not there.

--- iiimcf-comp.el.orig	2026-09-23 18:38:17
+++ iiimcf-comp.el	2026-09-23 18:38:17
@@ -32,15 +32,15 @@
 			       "./lisp/iiimcf-sc.el"))
       path file)
 
-;; Check Mule-UCS
+;; Check Mule-UCS.  The lisp only wants un-define for the UTF-16 coding
+;; systems, which Emacs 22 and later have of their own, so its absence is
+;; no longer fatal.  Asking for a path here is worse than useless in a
+;; batch build: read-from-minibuffer reads stdin, stdin is at end of file,
+;; and the loop never ends -- "End of file during parsing".
 
-(while (null (locate-library "un-define"))
-  (progn
-    (message "I cannot find Mule-UCS.")
-    (message "Please type the path where Mule-UCS is installed.")
-    (setq path (read-from-minibuffer ""))
-    (setq load-path (cons (expand-file-name path) load-path))))
-      
+(if (null (locate-library "un-define"))
+    (message "Mule-UCS not found; relying on the coding systems in Emacs."))
+
   (message "Remove old byte-compiled files-----")
   (mapcar 
    (lambda (x)
