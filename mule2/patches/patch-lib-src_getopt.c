$NetBSD$

Include the headers that declare what this file calls.

The declarations reached this file through some other header on the systems
it was built on, but not on glibc, where they are missing outright.  gcc 14
made an implicit declaration an error, so the build stops here.

--- lib-src/getopt.c.orig
+++ lib-src/getopt.c
@@ -47,6 +47,10 @@
 
 #include <stdio.h>
 
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+#include <string.h>
+
 /* Comment out all this code if we are using the GNU C Library, and are not
    actually compiling the library itself.  This code is part of the GNU C
    Library, but also included in many other GNU distributions.  Compiling
