$NetBSD$

When the JDK has no jdb, jde-get-jdk-prog returns nil and oset on the
:path slot errors before the user sees why.  Leave the slot alone in
that case.  From Debian.

--- jde-jdb.el.orig	2002-12-30 14:28:06.000000000 +0000
+++ jde-jdb.el
@@ -774,9 +774,11 @@
      (t
       (error "%s is not a valid jdb debugger choice." 
 	     (car jde-debugger))))
-    (oset 
-     jdb 
-     :path (jde-get-jdk-prog (oref jdb :exec-name)))
+    (let ((path (jde-get-jdk-prog (oref jdb :exec-name))))
+      (when path
+	(oset
+	 jdb
+	 :path path)))
     jdb))
 
 
