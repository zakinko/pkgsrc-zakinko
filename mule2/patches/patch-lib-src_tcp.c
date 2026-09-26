$NetBSD$

Include the headers that declare what this file calls.

The declarations reached this file through some other header on the systems
it was built on, but not on glibc, where they are missing outright.  gcc 14
made an implicit declaration an error, so the build stops here.

--- lib-src/tcp.c.orig
+++ lib-src/tcp.c
@@ -36,6 +36,11 @@
 #include <ctype.h>
 #include <sys/types.h>
 
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+#include <unistd.h>
+#include <string.h>
+
 #ifdef FUJITSU_UTS
 #define USG
 #include <sys/ucbtypes.h>
