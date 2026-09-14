$NetBSD$

Recognize DragonFly BSD.

DragonFly has <pthread_np.h> and pthread_getthreadid_np(), as FreeBSD
does, but only __FreeBSD__ selects that branch, so GetTID() falls
through to the last arm and returns a cast pthread_self() instead of the
id the system uses.

Submitted upstream as abseil/abseil-cpp#2160.

--- third_party/abseil-cpp/absl/base/internal/sysinfo.cc.orig
+++ third_party/abseil-cpp/absl/base/internal/sysinfo.cc
@@ -30,11 +30,11 @@
 #include <sys/syscall.h>
 #endif
 
-#if defined(__APPLE__) || defined(__FreeBSD__)
+#if defined(__APPLE__) || defined(__FreeBSD__) || defined(__DragonFly__)
 #include <sys/sysctl.h>
 #endif
 
-#ifdef __FreeBSD__
+#if defined(__FreeBSD__) || defined(__DragonFly__)
 #include <pthread_np.h>
 #endif
 
@@ -444,7 +444,7 @@
   return static_cast<pid_t>(tid);
 }
 
-#elif defined(__FreeBSD__)
+#elif defined(__FreeBSD__) || defined(__DragonFly__)
 
 pid_t GetTID() { return static_cast<pid_t>(pthread_getthreadid_np()); }
 
