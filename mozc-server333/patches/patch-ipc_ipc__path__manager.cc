$NetBSD: patch-ipc_ipc__path__manager.cc,v 1.7 2024/02/10 01:17:28 ryoon Exp $

--- ipc/ipc_path_manager.cc.orig
+++ ipc/ipc_path_manager.cc
@@ -391,7 +391,7 @@
   server_pid_ = pid;
 #endif  // __APPLE__
 
-#ifdef __linux__
+#if defined(__linux__) || defined(__NetBSD__)
   // load from /proc/<pid>/exe
   std::string proc = absl::StrFormat("/proc/%u/exe", pid);
   char filename[512];
