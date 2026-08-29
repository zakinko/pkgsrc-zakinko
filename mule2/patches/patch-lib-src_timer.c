$NetBSD$

Include the headers that declare what this file calls.

The declarations reached this file through some other header on the systems
it was built on, but not on glibc, where they are missing outright.  gcc 14
made an implicit declaration an error, so the build stops here.

--- lib-src/timer.c.orig
+++ lib-src/timer.c
@@ -20,6 +20,9 @@
 #include <sys/types.h>  /* time_t */
 
 #include <../src/config.h>
+
+/* Declare the standard functions this file calls. */
+#include <unistd.h>
 #undef read
 
 #ifdef LINUX
