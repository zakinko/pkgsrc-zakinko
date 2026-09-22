$NetBSD$

The mode calls outline-cycle from outline-magic without requiring it.
From Gentoo.

--- wikipedia-mode.el.orig
+++ wikipedia-mode.el
@@ -386,2 +386,3 @@
 (require 'font-lock)
+(require 'outline-magic)
 	
