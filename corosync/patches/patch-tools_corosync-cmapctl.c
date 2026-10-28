$NetBSD$

Pass isblank() an unsigned char.  The line comes from the file given to
corosync-cmapctl -p; a negative char indexes outside the table on
NetBSD, where the ctype functions are table lookups.

--- tools/corosync-cmapctl.c.orig
+++ tools/corosync-cmapctl.c
@@ -751,7 +751,7 @@
 		 */
 		ignore = 1;
 		for (c = 0; c < 1024; c++) {
-			if (isblank (buf[c])) {
+			if (isblank ((unsigned char)buf[c])) {
 				continue;
 			}
 
