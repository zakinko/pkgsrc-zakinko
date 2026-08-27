$NetBSD: patch-base_file_recursive.cc,v 1.1 2024/02/10 01:17:27 ryoon Exp $

Treat NetBSD like Linux here.  Upstream supports Linux, macOS, Windows,
Android and WASM only, so every POSIX path is spelled __linux__.

NetBSD has the fts(3) interface this code uses.

--- base/file/recursive.cc.orig
+++ base/file/recursive.cc
@@ -106,7 +106,8 @@
 }  // namespace
 
 #if (defined(__linux__) && !defined(__ANDROID__)) || \
-    (defined(TARGET_OS_OSX) && TARGET_OS_OSX)
+    (defined(TARGET_OS_OSX) && TARGET_OS_OSX) || \
+    defined(__NetBSD__)
 
 absl::Status DeleteRecursively(const zstring_view path) {
   // fts is not POSIX, but it's available on both Linux and MacOS.
