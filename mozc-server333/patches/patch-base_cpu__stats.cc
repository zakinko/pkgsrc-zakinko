$NetBSD: patch-base_cpu__stats.cc,v 1.5 2024/02/10 01:17:27 ryoon Exp $

Treat NetBSD like Linux here.  Upstream supports Linux, macOS, Windows,
Android and WASM only, so every POSIX path is spelled __linux__.

sysconf(_SC_NPROCESSORS_CONF) and /proc based CPU accounting work the same way.--- base/cpu_stats.cc.orig
+++ base/cpu_stats.cc
@@ -116,7 +116,8 @@
 
 #endif  // __APPLE__
 
-#if defined(__linux__) || defined(__wasm__)
+#if defined(__linux__) || defined(__wasm__) || defined(__NetBSD__) || defined(__FreeBSD__) || \
+    defined(__OpenBSD__) || defined(__DragonFly__)
   // NOT IMPLEMENTED
   // TODO(taku): implement Linux version
   // can take the info from /proc/stats
@@ -169,7 +170,8 @@
                              TimeValueTToInt64(task_times_info.system_time);
 #endif  // __APPLE__
 
-#if defined(__linux__) || defined(__wasm__)
+#if defined(__linux__) || defined(__wasm__) || defined(__NetBSD__) || defined(__FreeBSD__) || \
+    defined(__OpenBSD__) || defined(__DragonFly__)
   // not implemented
   const uint64_t total_times = 0;
   const uint64_t cpu_times = 0;
@@ -200,7 +202,8 @@
   return static_cast<size_t>(basic_info.avail_cpus);
 #endif  // __APPLE__
 
-#if defined(__linux__) || defined(__wasm__)
+#if defined(__linux__) || defined(__wasm__) || defined(__NetBSD__) || defined(__FreeBSD__) || \
+    defined(__OpenBSD__) || defined(__DragonFly__)
   // Not implemented
   return 1;
 #endif  // __linux__ || __wasm__
