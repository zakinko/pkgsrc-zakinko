$NetBSD$

Pass isdigit() an unsigned char.  The format comes from the logging
section of corosync.conf; a negative char indexes outside the table on
NetBSD, where the ctype functions are table lookups.

--- exec/logsys.c.orig
+++ exec/logsys.c
@@ -606,7 +606,7 @@
 		if (format_buffer[c] == '%') {
 			reminder = c;
 			for (c++; c < strlen(format_buffer); c++) {
-				if (isdigit(format_buffer[c])) {
+				if (isdigit((unsigned char)format_buffer[c])) {
 					continue;
 				}
 				if (format_buffer[c] == 't' ||
