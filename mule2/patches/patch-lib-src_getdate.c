$NetBSD$

Include the headers that declare what this file calls.

The declarations reached this file through some other header on the systems
it was built on, but not on glibc, where they are missing outright.  gcc 14
made an implicit declaration an error, so the build stops here.

--- lib-src/getdate.c.orig
+++ lib-src/getdate.c
@@ -204,6 +204,9 @@
 
 #include <stdio.h>
 
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+
 #ifndef __cplusplus
 #ifndef __STDC__
 #define const
