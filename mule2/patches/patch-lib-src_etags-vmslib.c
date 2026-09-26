$NetBSD$

Include the headers that declare what this file calls.

The declarations reached this file through some other header on the systems
it was built on, but not on glibc, where they are missing outright.  gcc 14
made an implicit declaration an error, so the build stops here.

--- lib-src/etags-vmslib.c.orig
+++ lib-src/etags-vmslib.c
@@ -87,6 +87,10 @@
 
 #include	<rmsdef.h>
 #include	<descrip.h>
+
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+#include <string.h>
 #define		OUTSIZE	MAX_FILE_SPEC_LEN
 short
 fn_exp(out, in)
