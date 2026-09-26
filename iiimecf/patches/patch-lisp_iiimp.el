$NetBSD$

un-define is a Mule-UCS file; see patch-lisp_EIMIL.el.

make-local-hook and process-kill-without-query are gone in modern Emacs, and
both sit where the package first reaches them: process-kill-without-query
right after the connection to the IIIM server is opened, make-local-hook when
a buffer starts watching for an asynchronous reply.  Since Emacs 21.1
add-hook creates the local hook itself when LOCAL is non-nil, which is how it
is called here, so nothing is lost by skipping the call.  Both are asked for
with fboundp rather than replaced, because this package is still built for
emacs20 and emacs21.
--- lisp/iiimp.el.orig
+++ lisp/iiimp.el
@@ -28,7 +28,7 @@
 
 ;;; Code:
 
-(require 'un-define)
+(require 'un-define nil t)
 
 (eval-and-compile
   (defvar iiimp-debug-flag nil
@@ -392,7 +392,9 @@
       (buffer-disable-undo buf)
       (setq proc
 	    (open-network-stream iiimp-process-name buf host port))
-      (process-kill-without-query proc)
+      (if (fboundp 'set-process-query-on-exit-flag)
+	  (set-process-query-on-exit-flag proc nil)
+	(process-kill-without-query proc))
       (set-process-coding-system proc 'binary 'binary)
       (set-process-sentinel
        proc (function iiimp-network-sentinel))
@@ -428,7 +430,8 @@
        'iiimp-async-invocation-handler)
       (setq iiimp-async-invocation-handler
 	    (cons com-id func))
-      (make-local-hook 'after-change-functions)
+      (if (fboundp 'make-local-hook)
+	  (make-local-hook 'after-change-functions))
       (add-hook 'after-change-functions
 		(function
 		 iiimp-async-invocation-handler-1)
