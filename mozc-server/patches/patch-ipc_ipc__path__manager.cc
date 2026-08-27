$NetBSD: patch-ipc_ipc__path__manager.cc,v 1.7 2024/02/10 01:17:28 ryoon Exp $

Look up the server's path on NetBSD, where /proc is not a required mount.

The Linux arm of IsValidServer reads /proc/<pid>/exe.  A machine that
inherits its fstab from the NetBSD boot images has procfs with noauto
(distrib/common/bootimage/fstab.in), so /proc is empty there and the
readlink fails with ENOENT.  kern.proc.<pid>.pathname depends on no mount,
and the __APPLE__ arm above already reads process information with sysctl.

--- ipc/ipc_path_manager.cc.orig	2023-10-26 12:00:50.000000000 +0000
+++ ipc/ipc_path_manager.cc
@@ -67,6 +67,11 @@
 #include "base/mac/mac_util.h"
 #endif  // __APPLE__
 
+#ifdef __NetBSD__
+#include <sys/param.h>
+#include <sys/sysctl.h>
+#endif  // __NetBSD__
+
 #ifdef _WIN32
 // clang-format off
 #include <windows.h>
@@ -389,6 +394,25 @@ bool IPCPathManager::IsValidServer(uint3
   server_pid_ = pid;
 #endif  // __APPLE__
 
+#ifdef __NetBSD__
+  // Do not read /proc/<pid>/exe here.  procfs is not a required mount on
+  // NetBSD -- the fstab that ships inside the NetBSD boot images carries it
+  // with noauto -- so the readlink would fail with ENOENT wherever /proc is
+  // not mounted.  kern.proc.<pid>.pathname depends on no mount, and the
+  // __APPLE__ branch above already reads process information with sysctl.
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
