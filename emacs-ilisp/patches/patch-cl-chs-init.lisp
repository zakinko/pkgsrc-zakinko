$NetBSD$

CLISP's sys::debug-unwind takes an argument.  Called without one it signals,
and the init file fails to load.

--- cl-chs-init.lisp.orig	2026-09-23 14:40:19
+++ cl-chs-init.lisp	2026-09-23 14:40:19
@@ -60,7 +60,7 @@
 (eval-when (:execute :load-toplevel)
   (when (not (compiled-function-p #'ilisp-inspect))
     (ilisp-message t "File is not compiled, use M-x ilisp-compile-inits"))
-  (sys::debug-unwind))
+  (sys::debug-unwind nil))
 
 
 ;;; end of file -- cl-chs-init.lsp --
