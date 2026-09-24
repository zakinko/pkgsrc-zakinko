$NetBSD$

Get the server path from sysctl on NetBSD.

NetBSD mounts procfs noauto, so /proc/<pid>/exe cannot be read on a stock
machine.  The FreeBSD branch already asks sysctl, but NetBSD was riding along
on the Linux one.  The MIB is not laid out as on FreeBSD: the pid is third and
KERN_PROC_PATHNAME fourth.

--- ipc/ipc_path_manager.cc.orig
+++ ipc/ipc_path_manager.cc
@@ -66,6 +66,12 @@
 
 #include "base/mac/mac_util.h"
 #endif  // __APPLE__
+
+#if defined(__FreeBSD__) || defined(__NetBSD__)
+#include <sys/sysctl.h>
+
+#include <climits>
+#endif  // __FreeBSD__ || __NetBSD__
 
 #ifdef _WIN32
 // clang-format off
@@ -388,7 +394,43 @@
   }
   server_pid_ = pid;
 #endif  // __APPLE__
+
+#ifdef __FreeBSD__
+  // FreeBSD does not mount procfs by default, so ask the kernel instead.
+  {
+    int name[] = {CTL_KERN, KERN_PROC, KERN_PROC_PATHNAME,
+                  static_cast<int>(pid)};
+    char path[PATH_MAX];
+    size_t path_len = sizeof(path);
+    if (sysctl(name, std::size(name), path, &path_len, nullptr, 0) < 0) {
+      LOG(ERROR) << "sysctl KERN_PROC_PATHNAME failed";
+      return false;
+    }
+    // path_len counts the terminating NUL.
+    server_path_.assign(path, path_len > 0 ? path_len - 1 : 0);
+    server_pid_ = pid;
+  }
+#endif  // __FreeBSD__
 
+#ifdef __NetBSD__
+  // NetBSD ships procfs as noauto, so /proc/<pid>/exe is absent on a stock
+  // install and this has to go through the kernel too.  The MIB is not the
+  // one FreeBSD uses: pid comes third and KERN_PROC_PATHNAME last.
+  {
+    int name[] = {CTL_KERN, KERN_PROC_ARGS, static_cast<int>(pid),
+                  KERN_PROC_PATHNAME};
+    char path[PATH_MAX];
+    size_t path_len = sizeof(path);
+    if (sysctl(name, std::size(name), path, &path_len, nullptr, 0) < 0) {
+      LOG(ERROR) << "sysctl KERN_PROC_PATHNAME failed";
+      return false;
+    }
+    // path_len counts the terminating NUL.
+    server_path_.assign(path, path_len > 0 ? path_len - 1 : 0);
+    server_pid_ = pid;
+  }
+#endif  // __NetBSD__
+
 #ifdef __linux__
   // load from /proc/<pid>/exe
   std::string proc = absl::StrFormat("/proc/%u/exe", pid);
