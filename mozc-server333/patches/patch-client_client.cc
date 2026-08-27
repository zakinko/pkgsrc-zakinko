$NetBSD: patch-client_client.cc,v 1.5 2024/02/10 01:17:27 ryoon Exp $

Treat NetBSD like Linux here.  Upstream supports Linux, macOS, Windows,
Android and WASM only, so every POSIX path is spelled __linux__.

--- client/client.cc.orig
+++ client/client.cc
@@ -888,7 +888,7 @@
     return false;
   }
 
-#if defined(_WIN32) || defined(__linux__)
+#if defined(_WIN32) || defined(__linux__) || defined(__NetBSD__)
   std::string arg = absl::StrCat("--mode=", mode);
   if (!extra_arg.empty()) {
     absl::StrAppend(&arg, " ", extra_arg);
