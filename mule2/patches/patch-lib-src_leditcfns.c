$NetBSD$

Include the headers that declare what this file calls.

The declarations reached this file through some other header on the systems
it was built on, but not on glibc, where they are missing outright.  gcc 14
made an implicit declaration an error, so the build stops here.

--- lib-src/leditcfns.c.orig
+++ lib-src/leditcfns.c
@@ -1,5 +1,9 @@
 #include <sgtty.h>
 #include <signal.h>
+
+/* Declare the standard functions this file calls. */
+#include <unistd.h>
+#include <string.h>
 #define STRLEN 100
 static char str[STRLEN+1] = "%?emacs"; /* extra char for the null */
 
