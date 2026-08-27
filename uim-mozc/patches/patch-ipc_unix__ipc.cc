$NetBSD: patch-ipc_unix__ipc.cc,v 1.1 2024/02/10 02:20:18 ryoon Exp $

Build the Unix domain IPC on NetBSD as well as Linux.

NetBSD has no SO_PEERCRED.  LOCAL_PEEREID fills a struct unpcbid instead, and
unp_pid is where the peer's process id comes from; without it IsPeerValid
leaves *pid at zero and IPCPathManager::IsValidServer returns at its first
statement, so the server is never checked.

The length passed to connect(2) and bind(2) has to be measured from
offsetof(sun_path).  NetBSD's sockaddr_un begins with a one byte sun_len, so
sizeof(sun_family) is one byte short and the last character of the socket
path is dropped.  On Linux sun_path also starts at two, so that part changes
nothing there.

--- ipc/unix_ipc.cc.orig	2023-10-26 12:00:50.000000000 +0000
+++ ipc/unix_ipc.cc
@@ -28,7 +28,7 @@
 // OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 // __linux__ only. Note that __ANDROID__/__wasm__ don't reach here.
-#if defined(__linux__)
+#if defined(__linux__) || defined(__NetBSD__)
 
 #include <fcntl.h>
 #include <sys/select.h>
@@ -119,6 +119,7 @@ bool IsWriteTimeout(int socket, absl::Du
 bool IsPeerValid(int socket, pid_t *pid) {
   *pid = 0;
 
+#if defined(__linux__)
   struct ucred peer_cred;
   int peer_cred_len = sizeof(peer_cred);
   if (getsockopt(socket, SOL_SOCKET, SO_PEERCRED, &peer_cred,
@@ -133,7 +134,23 @@ bool IsPeerValid(int socket, pid_t *pid)
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
 
@@ -263,7 +280,9 @@ void IPCClient::Init(const absl::string_
     address.sun_family = AF_UNIX;
     absl::SNPrintF(address.sun_path, sizeof(address.sun_path), "%s",
                    server_address);
-    const size_t sun_len = sizeof(address.sun_family) + server_address_length;
+    // sun_path does not start at sizeof(sun_family) on the BSDs (sun_len).
+    const size_t sun_len =
+        offsetof(struct sockaddr_un, sun_path) + server_address_length;
     pid_t pid = 0;
     if (::connect(socket_, reinterpret_cast<const sockaddr *>(&address),
                   sun_len) != 0 ||
@@ -376,7 +395,9 @@ IPCServer::IPCServer(const std::string &
   int on = 1;
   ::setsockopt(socket_, SOL_SOCKET, SO_REUSEADDR, reinterpret_cast<char *>(&on),
                sizeof(on));
-  const size_t sun_len = sizeof(addr.sun_family) + server_address_.size();
+  // sun_path does not start at sizeof(sun_family) on the BSDs (sun_len).
+  const size_t sun_len =
+      offsetof(struct sockaddr_un, sun_path) + server_address_.size();
   if (is_file_socket) {
     // Linux does not use files for IPC.
     ::chmod(server_address_.c_str(), 0600);
