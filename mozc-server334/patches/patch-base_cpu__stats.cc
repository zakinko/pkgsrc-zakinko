$NetBSD$

NetBSD の CPU 使用率は sysctl KERN_CP_TIME で取る。

--- base/cpu_stats.cc.orig
+++ base/cpu_stats.cc
@@ -116,7 +116,8 @@
 
 #endif  // __APPLE__
 
-#if defined(__linux__) || defined(__wasm__)
+#if defined(__linux__) || defined(__wasm__) || defined(__NetBSD__) || \
+    defined(__FreeBSD__)
   // NOT IMPLEMENTED
   // TODO(taku): implement Linux version
   // can take the info from /proc/stats
@@ -169,7 +170,8 @@
                              TimeValueTToInt64(task_times_info.system_time);
 #endif  // __APPLE__
 
-#if defined(__linux__) || defined(__wasm__)
+#if defined(__linux__) || defined(__wasm__) || defined(__NetBSD__) || \
+    defined(__FreeBSD__)
   // not implemented
   const uint64_t total_times = 0;
   const uint64_t cpu_times = 0;
@@ -200,7 +202,8 @@
   return static_cast<size_t>(basic_info.avail_cpus);
 #endif  // __APPLE__
 
-#if defined(__linux__) || defined(__wasm__)
+#if defined(__linux__) || defined(__wasm__) || defined(__NetBSD__) || \
+    defined(__FreeBSD__)
   // Not implemented
   return 1;
 #endif  // __linux__ || __wasm__
