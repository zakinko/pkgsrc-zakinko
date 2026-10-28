$NetBSD$

The test uses nothing from <net/ethernet.h>, which NetBSD does not have.

--- libknet/tests/fun_pmtud_crypto.c.orig
+++ libknet/tests/fun_pmtud_crypto.c
@@ -17,7 +17,7 @@
 #include <sys/ioctl.h>
 #ifdef KNET_SOLARIS
 #include <sys/sockio.h>
-#else
+#elif !defined(__NetBSD__)
 #include <net/ethernet.h>
 #endif
 #include <ifaddrs.h>
