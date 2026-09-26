$NetBSD$

jde-bug.el uses jde-util without requiring it, which the byte-compiler
notices.  From Debian.

--- jde-bug.el.orig	2002-12-30 14:28:06.000000000 +0000
+++ jde-bug.el
@@ -36,6 +36,7 @@
 ;;; Code:
 
 (require 'cl)
+(require 'jde-util)
 (require 'jde-parse)
 (require 'jde-dbs)
 (require 'jde-dbo)
