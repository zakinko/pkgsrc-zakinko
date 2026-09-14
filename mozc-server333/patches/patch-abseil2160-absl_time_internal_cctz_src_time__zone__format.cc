$NetBSD$

Do not define _XOPEN_SOURCE on DragonFly BSD.

cctz defines _XOPEN_SOURCE 500 so that <time.h> declares strptime(3),
and names the platforms where the define has the opposite effect so as
to skip it there.  DragonFly is not among them.

Submitted upstream as abseil/abseil-cpp#2160.  The upstream list also
carries __APPLE__, which the abseil mozc pins does not have yet; that
part is left alone here, since this package has not been built on macOS.

--- third_party/abseil-cpp/absl/time/internal/cctz/src/time_zone_format.cc.orig
+++ third_party/abseil-cpp/absl/time/internal/cctz/src/time_zone_format.cc
@@ -19,7 +19,8 @@
 #endif
 
 #if defined(HAS_STRPTIME) && HAS_STRPTIME
-#if !defined(_XOPEN_SOURCE) && !defined(__FreeBSD__) && !defined(__OpenBSD__)
+#if !defined(_XOPEN_SOURCE) && !defined(__FreeBSD__) && \
+    !defined(__OpenBSD__) && !defined(__DragonFly__)
 #define _XOPEN_SOURCE 500  // Exposes definitions for SUSv2 (UNIX 98).
 #endif
 #endif
