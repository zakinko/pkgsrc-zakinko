$NetBSD: patch-base_file_recursive.cc,v 1.1 2024/02/10 01:17:27 ryoon Exp $

Treat the BSDs like Linux here.  Upstream supports Linux, macOS, Windows,
Android and WASM only, so every POSIX path is spelled __linux__.

All four BSDs have the fts(3) interface this code uses.  Without this the
build falls through to the nftw() branch, which is only reached on Android
and iPhone -- and <ftw.h> is included only for those two, so FreeBSD failed
with a screenful of "use of undeclared identifier 'FTW_DP'".

--- base/file/recursive.cc.orig
+++ base/file/recursive.cc
@@ -106,7 +106,9 @@
 }  // namespace
 
 #if (defined(__linux__) && !defined(__ANDROID__)) || \
-    (defined(TARGET_OS_OSX) && TARGET_OS_OSX)
+    (defined(TARGET_OS_OSX) && TARGET_OS_OSX) || \
+    defined(__NetBSD__) || defined(__FreeBSD__) || \
+    defined(__OpenBSD__) || defined(__DragonFly__)
 
 absl::Status DeleteRecursively(const zstring_view path) {
   // fts is not POSIX, but it's available on both Linux and MacOS.
