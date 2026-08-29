$NetBSD: patch-ah,v 1.3 2012/12/11 04:54:43 dholland Exp $

NetBSD does not define the "unix" macro, so Funix_sync -- the unix-sync Lisp
function -- was compiled out here while it is present on other systems.  Define
it just before the test rather than changing the test, to keep the diff against
upstream small.

--- src/fileio.c.orig	2000-05-16 11:02:13.000000000 +0000
+++ src/fileio.c
@@ -3252,8 +3248,11 @@ The value is an integer.")
   return value;
 }
 
-#ifdef unix
+#ifdef __NetBSD__
+#define unix 42
+#endif
 
+#ifdef unix
 DEFUN ("unix-sync", Funix_sync, Sunix_sync, 0, 0, "",
   "Tell Unix to finish all pending disk updates.")
   ()
