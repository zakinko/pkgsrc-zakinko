$NetBSD$

Item 4: medit.el wrote to the fixed, predictable name /tmp/<user>.medit.mud
in a world-writable directory.  Move it into the per-user 0700 directory
(mule-user-temp-directory) so the fixed basename cannot be pre-empted with a
symlink.  Same rationale as patch-item4-ledit.

--- lisp/medit.el.orig	1995-01-01 00:00:00.000000000 +0000
+++ lisp/medit.el
@@ -31,7 +31,12 @@
 
 (require 'mim-mode)
 
-(defconst medit-zap-file (concat "/tmp/" (user-login-name) ".medit.mud")
+;; Was "/tmp/<user>.medit.mud", a predictable name in a world-writable
+;; directory; put it in a per-user 0700 directory so the fixed basename is
+;; safe from a pre-planted symlink.  See mule-user-temp-directory.
+(defconst medit-zap-file
+  (expand-file-name (concat (user-login-name) ".medit.mud")
+		    (mule-user-temp-directory))
   "File name for data sent to MDL by Medit.")
 (defconst medit-buffer "*MEDIT*"
   "Name of buffer in which Medit accumulates data to send to MDL.")
