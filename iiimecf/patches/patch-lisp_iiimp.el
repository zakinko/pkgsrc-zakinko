$NetBSD$

un-define is a Mule-UCS file; see patch-lisp_EIMIL.el.

--- lisp/iiimp.el.orig	2026-09-23 16:18:40
+++ lisp/iiimp.el	2026-09-23 16:18:40
@@ -28,7 +28,7 @@
 
 ;;; Code:
 
-(require 'un-define)
+(require 'un-define nil t)
 
 (eval-and-compile
   (defvar iiimp-debug-flag nil
