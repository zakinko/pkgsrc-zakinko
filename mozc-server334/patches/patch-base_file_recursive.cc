$NetBSD$

NetBSD を Linux と同じ枝に入れる。

--- base/file/recursive.cc.orig
+++ base/file/recursive.cc
@@ -103,8 +103,8 @@
 }
 }  // namespace
 
-#if (defined(__linux__) && !defined(__ANDROID__)) || \
-    (defined(TARGET_OS_OSX) && TARGET_OS_OSX)
+#if (defined(__linux__) && !defined(__ANDROID__)) || defined(__NetBSD__) || \
+    defined(__FreeBSD__) || (defined(TARGET_OS_OSX) && TARGET_OS_OSX)
 
 absl::Status DeleteRecursively(const absl::string_view path) {
   // fts is not POSIX, but it's available on both Linux and MacOS.
