$NetBSD: patch-ipc_ipc__path__manager.cc,v 1.7 2024/02/10 01:17:28 ryoon Exp $

Read the server path from sysctl on NetBSD instead of /proc/<pid>/exe.

procfs is not a required mount on NetBSD; the fstab that ships with the
NetBSD boot images carries it with noauto.  Where /proc is not mounted the
readlink fails with ENOENT, IsValidServer() returns false and the client
reports "Connecting to invalid server".

kern.proc.<pid>.pathname does not depend on any mount.  The same file
already reads process information through sysctl on macOS, and
inputmethod/mozc-server226 reads the path this way on NetBSD.

This must be applied together with the *pid fix in patch-ipc_unix__ipc.cc.
Neither is reachable without the other: while *pid stays 0 this code is
never entered.

--- ipc/ipc_path_manager.cc.orig
+++ ipc/ipc_path_manager.cc
@@ -68,6 +68,11 @@
 #include "base/mac/mac_util.h"
 #endif  // __APPLE__
 
+#ifdef __NetBSD__
+#include <sys/param.h>   // MAXPATHLEN
+#include <sys/sysctl.h>
+#endif  // __NetBSD__
+
 #ifdef _WIN32
 // clang-format off
 #include <windows.h>
@@ -391,6 +396,25 @@
   server_pid_ = pid;
 #endif  // __APPLE__
 
+#ifdef __NetBSD__
+  // Do not read /proc/<pid>/exe here.  procfs is not a required mount on
+  // NetBSD: the fstab that ships with the NetBSD boot images carries it
+  // with noauto, so the readlink below fails with ENOENT wherever /proc is
+  // not mounted.  kern.proc.<pid>.pathname does not depend on any mount,
+  // and inputmethod/mozc-server226 already reads the path this way.
+  int name[] = {CTL_KERN, KERN_PROC_ARGS, static_cast<int>(pid),
+                KERN_PROC_PATHNAME};
+  char path[MAXPATHLEN];
+  size_t path_len = sizeof(path);
+  if (sysctl(name, std::size(name), path, &path_len, nullptr, 0) < 0) {
+    LOG(ERROR) << "sysctl KERN_PROC_PATHNAME failed: " << strerror(errno);
+    return false;
+  }
+
+  server_path_ = path;
+  server_pid_ = pid;
+#endif  // __NetBSD__
+
 #ifdef __linux__
   // load from /proc/<pid>/exe
   std::string proc = absl::StrFormat("/proc/%u/exe", pid);
