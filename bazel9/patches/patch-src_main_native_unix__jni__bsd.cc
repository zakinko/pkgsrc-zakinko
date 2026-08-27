$NetBSD$

Say which of the optional interfaces NetBSD has.

This file is written for whichever BSD is compiling it and expects each to
declare what it offers.  NetBSD has neither extattr(2) nor
sysctlbyname(3), which is the same answer OpenBSD gives.

--- src/main/native/unix_jni_bsd.cc.orig
+++ src/main/native/unix_jni_bsd.cc
@@ -15,6 +15,8 @@
 #if defined(__FreeBSD__)
 # define HAVE_EXTATTR
 # define HAVE_SYSCTLBYNAME
+#elif defined(__NetBSD__)
+// No sys/extattr.h or sysctlbyname on this platform.
 #elif defined(__OpenBSD__)
 // No sys/extattr.h or sysctlbyname on this platform.
 #else
