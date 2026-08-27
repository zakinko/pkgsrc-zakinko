$NetBSD: patch-ipc_unix__ipc.cc,v 1.7 2024/02/10 01:17:28 ryoon Exp $

Portability fixes for NetBSD in the IPC layer, and two bugs in the NetBSD
support that pkgsrc has been carrying since 2024.

1. SO_PEERCRED does not exist on NetBSD.  Use LOCAL_PEEREID with
   struct unpcbid instead.

2. The NetBSD branch never stored the peer pid, so *pid stayed 0 and
   IPCPathManager::IsValidServer() returned true from its first line,
   skipping the check that the peer really is mozc_server.

3. sun_len was computed as sizeof(sun_family) + path length.  That is
   correct on Linux, where sun_family is 2 bytes and sun_path starts at
   offset 2, but on NetBSD sockaddr_un starts with a 1 byte sun_len and
   sa_family_t is 1 byte, so the value was one byte short and the last
   character of every socket path was cut off:

     /tmp/.mozc.<key>.session       became .sessio
     /tmp/.mozc.<key>.renderer.:99  became .renderer.:9

   Client and server truncate identically, so this never broke anything
   visibly.  offsetof(struct sockaddr_un, sun_path) is correct on both
   platforms and generates identical code on Linux.

--- ipc/unix_ipc.cc.orig
+++ ipc/unix_ipc.cc
@@ -28,7 +28,7 @@
 // OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 // __linux__ only. Note that __ANDROID__/__wasm__ don't reach here.
-#if defined(__linux__)
+#if defined(__linux__) || defined(__NetBSD__)
 
 #include <fcntl.h>
 #include <sys/select.h>
@@ -36,6 +36,8 @@
 #include <sys/stat.h>
 #include <sys/time.h>
 #include <sys/un.h>
+
+#include <stddef.h>
 #include <unistd.h>
 
 #include <cerrno>
@@ -121,6 +123,7 @@
 bool IsPeerValid(int socket, pid_t *pid) {
   *pid = 0;
 
+#if defined(__linux__)
   struct ucred peer_cred;
   int peer_cred_len = sizeof(peer_cred);
   if (getsockopt(socket, SOL_SOCKET, SO_PEERCRED, &peer_cred,
@@ -135,7 +138,23 @@
   }
 
   *pid = peer_cred.pid;
+#elif defined(__NetBSD__)
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
 
+  *pid = peer_cred.unp_pid;
+#endif
   return true;
 }
 
@@ -265,7 +284,8 @@
     address.sun_family = AF_UNIX;
     absl::SNPrintF(address.sun_path, sizeof(address.sun_path), "%s",
                    server_address);
-    const size_t sun_len = sizeof(address.sun_family) + server_address_length;
+    const size_t sun_len =
+        offsetof(struct sockaddr_un, sun_path) + server_address_length;
     pid_t pid = 0;
     if (::connect(socket_, reinterpret_cast<const sockaddr *>(&address),
                   sun_len) != 0 ||
@@ -378,7 +398,8 @@
   int on = 1;
   ::setsockopt(socket_, SOL_SOCKET, SO_REUSEADDR, reinterpret_cast<char *>(&on),
                sizeof(on));
-  const size_t sun_len = sizeof(addr.sun_family) + server_address_.size();
+  const size_t sun_len =
+      offsetof(struct sockaddr_un, sun_path) + server_address_.size();
   if (is_file_socket) {
     // Linux does not use files for IPC.
     ::chmod(server_address_.c_str(), 0600);
