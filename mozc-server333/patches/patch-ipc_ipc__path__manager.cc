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
 
+#if defined(__NetBSD__) || defined(__FreeBSD__) || defined(__DragonFly__)
+#include <sys/param.h>   // MAXPATHLEN
+#include <sys/sysctl.h>
+#endif  // BSD with KERN_PROC_PATHNAME
+
 #ifdef _WIN32
 // clang-format off
 #include <windows.h>
@@ -391,6 +396,66 @@
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
+#if defined(__FreeBSD__) || defined(__DragonFly__)
+  // FreeBSD and DragonFly do not mount procfs by default either, and their
+  // MIB is not the one NetBSD uses: KERN_PROC comes second and the pid
+  // last.  sysctl can succeed and return nothing -- passing NetBSD's order
+  // here is one way to get that -- so the length is checked as well.
+  //
+  // On DragonFly this branch is not reached today: IsPeerValid() cannot
+  // obtain a peer pid there, so IsValidServer() returns early.  It is kept
+  // because the MIB does work, and because leaving DragonFly out would
+  // break it the day its xucred grows a cr_pid.
+  {
+    int name[] = {CTL_KERN, KERN_PROC, KERN_PROC_PATHNAME,
+                  static_cast<int>(pid)};
+    char path[MAXPATHLEN];
+    size_t path_len = sizeof(path);
+    memset(path, 0, sizeof(path));
+    if (sysctl(name, std::size(name), path, &path_len, nullptr, 0) < 0 ||
+        path_len == 0) {
+      LOG(ERROR) << "sysctl KERN_PROC_PATHNAME failed";
+      return false;
+    }
+    // path_len counts the terminating NUL.
+    server_path_.assign(path, path_len - 1);
+    server_pid_ = pid;
+  }
+#endif  // __FreeBSD__ || __DragonFly__
+
+#ifdef __OpenBSD__
+  // OpenBSD has no KERN_PROC_PATHNAME and mounts no procfs, so the
+  // executable behind a pid cannot be recovered.  The peer pid *is*
+  // available here (SO_PEERCRED, see unix_ipc.cc) but there is nothing to
+  // compare it against.
+  //
+  // Return without touching server_pid_ or server_path_.  Falling through
+  // would compare the caller's path against the string cleared above and
+  // refuse every connection; caching the pid would make the second call
+  // take the early return at the top of this function and refuse from then
+  // on.  On OpenBSD the uid check in IsPeerValid() is the only guard.
+  return true;
+#endif  // __OpenBSD__
+
 #ifdef __linux__
   // load from /proc/<pid>/exe
   std::string proc = absl::StrFormat("/proc/%u/exe", pid);
