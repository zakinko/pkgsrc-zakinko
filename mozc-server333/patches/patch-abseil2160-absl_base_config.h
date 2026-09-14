$NetBSD$

Recognize DragonFly BSD.

ABSL_HAVE_MMAP and ABSL_HAVE_PTHREAD_GETSCHEDPARAM are each set from a
list of platforms named one by one, and DragonFly is on neither list,
so abseil is built there as if it had neither mmap(2) nor
pthread_getschedparam(3).  Both are present.

Submitted upstream as abseil/abseil-cpp#2160.  That change is against a
newer abseil than the one mozc pins, where the two lists are wrapped
across different lines, so this is the same change written out for this
tree rather than the upstream diff.

--- third_party/abseil-cpp/absl/base/config.h.orig
+++ third_party/abseil-cpp/absl/base/config.h
@@ -379,7 +379,8 @@
     defined(__asmjs__) || defined(__EMSCRIPTEN__) || defined(__Fuchsia__) || \
     defined(__sun) || defined(__myriad2__) || defined(__HAIKU__) ||          \
     defined(__OpenBSD__) || defined(__NetBSD__) || defined(__QNX__) ||       \
-    defined(__VXWORKS__) || defined(__hexagon__) || defined(__XTENSA__)
+    defined(__VXWORKS__) || defined(__hexagon__) || defined(__XTENSA__) ||   \
+    defined(__DragonFly__)
 #define ABSL_HAVE_MMAP 1
 #endif
 
@@ -391,7 +392,7 @@
 #error ABSL_HAVE_PTHREAD_GETSCHEDPARAM cannot be directly set
 #elif defined(__linux__) || defined(__APPLE__) || defined(__FreeBSD__) || \
     defined(_AIX) || defined(__ros__) || defined(__OpenBSD__) ||          \
-    defined(__NetBSD__) || defined(__VXWORKS__)
+    defined(__NetBSD__) || defined(__VXWORKS__) || defined(__DragonFly__)
 #define ABSL_HAVE_PTHREAD_GETSCHEDPARAM 1
 #endif
 
