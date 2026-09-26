$NetBSD$

Item 4: ledit.el placed its scratch files at the fixed, predictable names
/tmp/<user>.l1 (written), .l2 (loaded as Lisp!) and .l4 (written), in a
world-writable directory -- a symlink/pre-created-file attack, and the .l2
load is arbitrary code execution.  The basenames are a protocol with the
external Lisp and cannot be randomised, so put them in a per-user 0700
directory (mule-user-temp-directory, patch-foundation-make-temp-file), where
no other user can create an entry.  This is the same private-directory idea
GNU Emacs used for its server socket (03ae35cf); upstream itself only ever
moved these files to temporary-file-directory (dee8319, 1999) and later
obsoleted ledit rather than making it safe.

--- lisp/ledit.el.orig	1995-01-01 00:00:00.000000000 +0000
+++ lisp/ledit.el
@@ -32,12 +32,20 @@
 
 (defvar ledit-mode-map nil)
 
-(defconst ledit-zap-file (concat "/tmp/" (user-login-name) ".l1")
+;; These were "/tmp/<user>.lN" -- a fixed, predictable name in a
+;; world-writable directory, so another user could pre-plant a symlink and
+;; make the write-region/load below follow it (the .l2 case even loads Lisp).
+;; The basenames are a protocol with the external Lisp, so they cannot be
+;; randomised; put them in a per-user 0700 directory instead, where only we
+;; can create entries.  See mule-user-temp-directory.
+(defconst ledit-zap-file
+  (expand-file-name (concat (user-login-name) ".l1") (mule-user-temp-directory))
   "File name for data sent to Lisp by Ledit.")
-(defconst ledit-read-file (concat "/tmp/" (user-login-name) ".l2")
+(defconst ledit-read-file
+  (expand-file-name (concat (user-login-name) ".l2") (mule-user-temp-directory))
   "File name for data sent to Ledit by Lisp.")
-(defconst ledit-compile-file 
-  (concat "/tmp/" (user-login-name) ".l4")
+(defconst ledit-compile-file
+  (expand-file-name (concat (user-login-name) ".l4") (mule-user-temp-directory))
   "File name for data sent to Lisp compiler by Ledit.")
 (defconst ledit-buffer "*LEDIT*"
   "Name of buffer in which Ledit accumulates data to send to Lisp.")
