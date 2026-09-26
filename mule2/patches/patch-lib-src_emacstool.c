$NetBSD$

Include the headers that declare what this file calls.

The declarations reached this file through some other header on the systems
it was built on, but not on glibc, where they are missing outright.  gcc 14
made an implicit declaration an error, so the build stops here.

--- lib-src/emacstool.c.orig
+++ lib-src/emacstool.c
@@ -111,6 +111,11 @@
 static short default_image[258] = 
 {
 #include <images/terminal.icon>
+
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+#include <string.h>
+#include <fcntl.h>
 };
 mpr_static(icon_image, 64, 64, 1, default_image);
 
