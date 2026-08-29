$NetBSD: patch-bc,v 1.1.1.1 2003/04/11 00:31:45 uebayasi Exp $

site-init.el is read while emacs is being dumped, so what it sets is baked into
the binary.  Two things are set here: NetBSD keeps info files under /usr/share,
which is not in the default Info path, and send-pr.el is autoloaded from where
the base system puts it.

--- /dev/null	Fri Mar 26 07:52:59 1999
+++ lisp/site-init.el	Wed Mar 24 09:37:17 1999
@@ -0,0 +1,7 @@
+;; NetBSD puts info files in /usr/share.
+(setq Info-default-directory-list
+      (cons "/usr/share/info/"
+	    Info-default-directory-list))
+
+(autoload 'send-pr "/usr/share/gnats/send-pr.el" 
+  "Command to create and send a problem report." t)
