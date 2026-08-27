$NetBSD$

* NetBSD support

* Do not cut the last byte off the socket path.  sun_path does not
  start right after sun_family on NetBSD; there is a one byte sun_len
  in front of it, so sizeof(sun_family) is one short and
  /tmp/.mozc.<key>.session is created as .sessio.

* Set *pid in the NetBSD branch of IsPeerValid, as the Linux branch
  does.  Without it IPCPathManager::IsValidServer() takes its
  "if (pid == 0) return true" path and never checks the peer.

* kern.proc.args wants four MIB elements, and the third one has to be
  KERN_PROC_PATHNAME to get a path rather than the argv block.

--- ipc/unix_ipc.cc.orig
+++ ipc/unix_ipc.cc
@@ -28,7 +28,7 @@
 // OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 // OS_LINUX only. Note that OS_ANDROID/OS_WASM don't reach here.
-#if defined(OS_LINUX)
+#if defined(OS_LINUX) || defined(OS_NETBSD)
 
 #include <arpa/inet.h>
 #include <fcntl.h>
@@ -39,6 +39,8 @@
 #include <sys/time.h>
 #include <sys/types.h>
 #include <sys/un.h>
+
+#include <cstddef>
 #include <sys/wait.h>
 #include <unistd.h>
 
@@ -125,7 +127,7 @@
   // sometimes doesn't support the getsockopt(sock, SOL_SOCKET, SO_PEERCRED)
   // system call.
   // TODO(yusukes): Add implementation for ARM Linux.
-#ifndef __arm__
+#if !defined(__arm__) && !defined(OS_NETBSD)
   struct ucred peer_cred;
   int peer_cred_len = sizeof(peer_cred);
   if (getsockopt(socket, SOL_SOCKET, SO_PEERCRED,
@@ -141,7 +143,28 @@
   }
 
   *pid = peer_cred.pid;
-#endif  // __arm__
+#endif  // __arm__ || OS_NETBSD
+
+#if defined(OS_NETBSD)
+  struct unpcbid peer_cred;
+  int peer_cred_len = sizeof(peer_cred);
+  if (getsockopt(socket, 0, LOCAL_PEEREID,
+                 reinterpret_cast<void *>(&peer_cred),
+                 reinterpret_cast<socklen_t *>(&peer_cred_len)) < 0) {
+    LOG(ERROR) << "cannot get peer credential. Not a Unix socket?";
+    return false;
+  }
+
+  if (peer_cred.unp_euid!= ::geteuid()) {
+    LOG(WARNING) << "uid mismatch." << peer_cred.unp_euid << "!=" << ::geteuid();
+    return false;
+  }
+
+  // Without this the caller sees pid 0, and IPCPathManager::IsValidServer()
+  // returns early on "if (pid == 0) return true", so the check that the peer
+  // really is mozc_server never runs.
+  *pid = peer_cred.unp_pid;
+#endif
 
   return true;
 }
@@ -274,7 +297,11 @@
     address.sun_family = AF_UNIX;
     ::memcpy(address.sun_path, server_address.data(), server_address_length);
     address.sun_path[server_address_length] = '\0';
-    const size_t sun_len = sizeof(address.sun_family) + server_address_length;
+    // sun_path does not start right after sun_family on every system.
+    // NetBSD puts a one byte sun_len in front of it, so sizeof(sun_family)
+    // is one short there and the last byte of the path is cut off.
+    const size_t sun_len =
+        offsetof(struct sockaddr_un, sun_path) + server_address_length;
     pid_t pid = 0;
     if (::connect(socket_, reinterpret_cast<const sockaddr *>(&address),
                   sun_len) != 0 ||
@@ -381,7 +408,9 @@
   int on = 1;
   ::setsockopt(socket_, SOL_SOCKET, SO_REUSEADDR, reinterpret_cast<char *>(&on),
                sizeof(on));
-  const size_t sun_len = sizeof(addr.sun_family) + server_address_.size();
+  // See the comment on the connect() side above.
+  const size_t sun_len =
+      offsetof(struct sockaddr_un, sun_path) + server_address_.size();
   if (!IsAbstractSocket(server_address_)) {
     // Linux does not use files for IPC.
     ::chmod(server_address_.c_str(), 0600);
@@ -468,4 +497,4 @@
 
 }  // namespace mozc
 
-#endif  // OS_LINUX
+#endif  // OS_LINUX || OS_NETBSD
