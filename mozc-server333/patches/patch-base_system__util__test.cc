$NetBSD: patch-base_system__util__test.cc,v 1.1 2024/02/10 01:17:27 ryoon Exp $

Treat NetBSD like Linux here.  Upstream supports Linux, macOS, Windows,
Android and WASM only, so every POSIX path is spelled __linux__.

--- base/system_util_test.cc.orig
+++ base/system_util_test.cc
@@ -55,7 +55,7 @@
 #elif defined(__APPLE__)
   // TODO(komatsu): write a test.
 
-#elif defined(__linux__)
+#elif defined(__linux__) || defined(__NetBSD__)
   EnvironMock environ_mock;
   FileUtilMock file_util_mock;
   SystemUtil::SetUserProfileDirectory("");
