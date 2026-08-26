$NetBSD$

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
