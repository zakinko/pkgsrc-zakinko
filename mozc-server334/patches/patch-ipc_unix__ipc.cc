$NetBSD$

NetBSD で unix domain socket の相手を確かめる。

peer の credential は LOCAL_PEEREID と struct unpcbid で取る。あわせて
sockaddr_un の長さを offsetof で数える。sizeof(sun_family) は sun_path の
offset ではない。NetBSD の sun_family は 1 バイトで前に sun_len があるので、
一文字短い path を bind してしまう。

--- ipc/unix_ipc.cc.orig
+++ ipc/unix_ipc.cc
@@ -27,8 +27,9 @@
 // (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 // OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
-// __linux__ only. Note that __ANDROID__/__wasm__ don't reach here.
-#if defined(__linux__)
+// __linux__ and the BSDs only. Note that __ANDROID__/__wasm__ don't reach
+// here.
+#if defined(__linux__) || defined(__NetBSD__) || defined(__FreeBSD__)
 
 #include <fcntl.h>
 #include <sys/select.h>
@@ -38,6 +39,10 @@
 #include <sys/un.h>
 #include <unistd.h>
 
+#ifdef __FreeBSD__
+#include <sys/ucred.h>
+#endif  // __FreeBSD__
+
 #include <cerrno>
 #include <cstddef>
 #include <cstdint>
@@ -120,7 +125,47 @@
 
 bool IsPeerValid(int socket, pid_t *pid) {
   *pid = 0;
+
+#if defined(__NetBSD__)
+  // NetBSD has no SO_PEERCRED.  The equivalent is LOCAL_PEEREID on the
+  // unix domain protocol level, which fills in struct unpcbid.
+  struct unpcbid peer_cred;
+  int peer_cred_len = sizeof(peer_cred);
+  if (getsockopt(socket, 0, LOCAL_PEEREID, &peer_cred,
+                 reinterpret_cast<socklen_t *>(&peer_cred_len)) < 0) {
+    LOG(ERROR) << "cannot get peer credential. Not a Unix socket?";
+    return false;
+  }
+
+  if (peer_cred.unp_euid != ::geteuid()) {
+    LOG(WARNING) << "uid mismatch." << peer_cred.unp_euid << "!="
+                 << ::geteuid();
+    return false;
+  }
+
+  *pid = peer_cred.unp_pid;
+#elif defined(__FreeBSD__)
+  // FreeBSD has no SO_PEERCRED either.  LOCAL_PEERCRED fills in struct
+  // xucred, which carries the peer's pid.
+  struct xucred peer_cred;
+  socklen_t peer_cred_len = sizeof(peer_cred);
+  if (getsockopt(socket, 0, LOCAL_PEERCRED, &peer_cred, &peer_cred_len) < 0) {
+    LOG(ERROR) << "cannot get peer credential. Not a Unix socket?";
+    return false;
+  }
 
+  if (peer_cred.cr_version != XUCRED_VERSION) {
+    LOG(ERROR) << "unexpected xucred version " << peer_cred.cr_version;
+    return false;
+  }
+
+  if (peer_cred.cr_uid != ::geteuid()) {
+    LOG(WARNING) << "uid mismatch." << peer_cred.cr_uid << "!=" << ::geteuid();
+    return false;
+  }
+
+  *pid = peer_cred.cr_pid;
+#else   // __FreeBSD__
   struct ucred peer_cred;
   int peer_cred_len = sizeof(peer_cred);
   if (getsockopt(socket, SOL_SOCKET, SO_PEERCRED, &peer_cred,
@@ -135,6 +180,7 @@
   }
 
   *pid = peer_cred.pid;
+#endif  // !__linux__
 
   return true;
 }
@@ -265,7 +311,12 @@
     address.sun_family = AF_UNIX;
     absl::SNPrintF(address.sun_path, sizeof(address.sun_path), "%s",
                    server_address);
-    const size_t sun_len = sizeof(address.sun_family) + server_address_length;
+    // sizeof(sun_family) is not the offset of sun_path.  NetBSD's
+    // sockaddr_un leads with a one byte sun_len and has a one byte
+    // sa_family_t, so adding sizeof(sun_family) is one short there and the
+    // last character of the path is cut off.
+    const size_t sun_len =
+        offsetof(struct sockaddr_un, sun_path) + server_address_length;
     pid_t pid = 0;
     if (::connect(socket_, reinterpret_cast<const sockaddr *>(&address),
                   sun_len) != 0 ||
@@ -381,7 +432,8 @@
   int on = 1;
   ::setsockopt(socket_, SOL_SOCKET, SO_REUSEADDR, reinterpret_cast<char *>(&on),
                sizeof(on));
-  const size_t sun_len = sizeof(addr.sun_family) + server_address_.size();
+  const size_t sun_len =
+      offsetof(struct sockaddr_un, sun_path) + server_address_.size();
   if (is_file_socket) {
     // Linux does not use files for IPC.
     ::chmod(server_address_.c_str(), 0600);
