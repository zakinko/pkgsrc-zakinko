$NetBSD$

* NetBSD support

* kern.proc.args wants four MIB elements, and the fourth has to be
  KERN_PROC_PATHNAME to get a path rather than the argv block.  With
  three elements sysctl(3) returns EINVAL every time.

* Fill server_path_ before the comparison, not after it.  The block
  used to sit below "if (server_path == server_path_)", so the value
  it computed was never the one compared and IsValidServer() always
  returned false.  Set server_pid_ too, as the Linux branch does.

* sysctl(3) counts the terminating NUL; drop it before comparing.

--- ipc/ipc_path_manager.cc.orig
+++ ipc/ipc_path_manager.cc
@@ -53,6 +53,11 @@
 #endif  // __APPLE__
 #endif  // OS_WIN
 
+#if defined(OS_NETBSD)
+#include <sys/param.h>
+#include <sys/sysctl.h>
+#endif
+
 #include <cstdlib>
 #include <map>
 #ifdef OS_WIN
@@ -420,6 +425,34 @@
   server_pid_ = pid;
 #endif  // OS_LINUX
 
+#if defined(OS_NETBSD)
+  // kern.proc.args takes four elements, and the fourth has to be
+  // KERN_PROC_PATHNAME: KERN_PROC_ARGV gives the argv block, not a path.
+  // This has to run before the comparison below, not after it; filling
+  // server_path_ afterwards leaves the comparison looking at the value
+  // from the previous call and IsValidServer() always returns false.
+  {
+    int name[] = { CTL_KERN, KERN_PROC_ARGS, static_cast<int>(pid),
+                   KERN_PROC_PATHNAME };
+    size_t data_len = 0;
+    if (sysctl(name, arraysize(name), NULL, &data_len, NULL, 0) < 0) {
+      LOG(ERROR) << "sysctl KERN_PROC_PATHNAME failed";
+      return false;
+    }
+    server_path_.resize(data_len);
+    if (sysctl(name, arraysize(name), &server_path_[0],
+               &data_len, NULL, 0) < 0) {
+      LOG(ERROR) << "sysctl KERN_PROC_PATHNAME failed";
+      return false;
+    }
+    // sysctl(3) counts the terminating NUL; std::string must not keep it.
+    while (!server_path_.empty() && server_path_.back() == '\0') {
+      server_path_.pop_back();
+    }
+    server_pid_ = pid;
+  }
+#endif  // OS_NETBSD
+
   VLOG(1) << "server path: " << server_path << " " << server_path_;
   if (server_path == server_path_) {
     return true;
