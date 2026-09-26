$NetBSD$

vm-folder calls vm-add-write-file-hook at load time, but required
vm-misc, where it is defined, only when compiling.  Loading vm-folder on
its own failed with void-function vm-add-write-file-hook.

--- lisp/vm-folder.el.orig
+++ lisp/vm-folder.el
@@ -24,6 +24,9 @@
 
 (provide 'vm-folder)
 
+;; vm-add-write-file-hook, called at the end of this file, is in vm-misc.
+(require 'vm-misc)
+
 (eval-when-compile
   (require 'vm-misc)
   (require 'vm-summary)
