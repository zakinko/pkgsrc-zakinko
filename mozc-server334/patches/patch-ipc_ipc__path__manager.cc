$NetBSD$

NetBSD で server の path を sysctl から取る。

NetBSD の procfs は noauto なので、素の箱では /proc/<pid>/exe が読めない。
FreeBSD の枝は既に sysctl を叩いているのに、NetBSD だけ Linux の枝に相乗り
していた。MIB の並びは FreeBSD と違い、pid が三番目で KERN_PROC_PATHNAME が
四番目になる。

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
