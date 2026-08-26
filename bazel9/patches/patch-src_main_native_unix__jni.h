$NetBSD$

--- src/main/native/unix_jni.h.orig
+++ src/main/native/unix_jni.h
@@ -26,7 +26,8 @@
 
 namespace blaze_jni {
 
-#if defined(__APPLE__) || defined(__FreeBSD__) || defined(__OpenBSD__)
+#if defined(__APPLE__) || defined(__FreeBSD__) || defined(__OpenBSD__) || \
+    defined(__NetBSD__)
 // stat64 is deprecated on OS X/BSD.
 typedef struct stat portable_stat_struct;
 #define portable_stat ::stat
