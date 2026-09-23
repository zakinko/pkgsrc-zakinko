$NetBSD$

Register and unregister descriptors through the seam.

Unlike n-acd, the descriptors here come and go - the packet socket is dropped
once a lease is taken - so the seam has add and del rather than one
registration at creation.

--- src/n-dhcp4/src/n-dhcp4-c-connection.c.orig
+++ src/n-dhcp4/src/n-dhcp4-c-connection.c
@@ -8,13 +8,11 @@
 #include <c-stdaux.h>
 #include <errno.h>
 #include <limits.h>
-#include <sys/socket.h> /* needed by linux/netdevice.h */
-#include <linux/netdevice.h>
+#include <sys/socket.h>
 #include <net/if_arp.h>
 #include <stdbool.h>
 #include <stdlib.h>
 #include <string.h>
-#include <sys/epoll.h>
 #include "n-dhcp4-private.h"
 #include "util/packet.h"
 
@@ -24,7 +22,7 @@
  * @client_config:              client configuration to use
  * @probe_config:               client probe configuration to use
  * @log_queue:                  the log queue for logging events
- * @fd_epoll:                   epoll context to attach to, or -1
+ * @fd_poll:                   epoll context to attach to, or -1
  *
  * This initializes a new client connection using the configuration given in
  * @client_config and @probe_config.
@@ -35,9 +33,9 @@
  * meantime. Same is true for @probe_config.
  *
  * The new connection automatically attaches to the epoll context given as
- * @fd_epoll. The epoll FD is retained in the connection and the caller must
+ * @fd_poll. The epoll FD is retained in the connection and the caller must
  * guarantee that it lives as long as the connection.
- * The caller is explicitly allowed to pass -1 as @fd_epoll, in which case the
+ * The caller is explicitly allowed to pass -1 as @fd_poll, in which case the
  * connection will initialize correctly, but will not be in a usable state.
  * That is, any call to n_dhcp4_c_connection_listen() will fail, since it will
  * be unable to attach to the epoll context. Such a connection can be used to
@@ -49,11 +47,11 @@
                               NDhcp4ClientConfig *client_config,
                               NDhcp4ClientProbeConfig *probe_config,
                               NDhcp4LogQueue *log_queue,
-                              int fd_epoll) {
+                              int fd_poll) {
         *connection = (NDhcp4CConnection)N_DHCP4_C_CONNECTION_NULL(*connection);
         connection->client_config = client_config;
         connection->probe_config = probe_config;
-        connection->fd_epoll = fd_epoll;
+        connection->fd_poll = fd_poll;
         connection->log_queue = log_queue;
 
         /*
@@ -67,7 +65,7 @@
          * directly passing -1 in the constructor, you are guaranteed not even
          * the constructor can ever mess with your epoll-set.
          */
-        if (connection->fd_epoll < 0)
+        if (connection->fd_poll < 0)
                 connection->state = N_DHCP4_C_CONNECTION_STATE_CLOSED;
 
         return 0;
@@ -150,13 +148,13 @@
                  connection->state == N_DHCP4_C_CONNECTION_STATE_UDP);
 
         if (connection->fd_packet >= 0) {
-                epoll_ctl(connection->fd_epoll, EPOLL_CTL_DEL, connection->fd_packet, NULL);
+                n_dhcp4_os_poll_del(connection->fd_poll, connection->fd_packet);
                 connection->fd_packet = c_close(connection->fd_packet);
                 connection->ns_drain_timeout = 0;
         }
 
         if (connection->fd_udp >= 0) {
-                epoll_ctl(connection->fd_epoll, EPOLL_CTL_DEL, connection->fd_udp, NULL);
+                n_dhcp4_os_poll_del(connection->fd_poll, connection->fd_udp);
                 connection->fd_udp = c_close(connection->fd_udp);
         }
 
@@ -164,15 +162,10 @@
         if (r)
                 return r;
 
-        r = epoll_ctl(connection->fd_epoll,
-                      EPOLL_CTL_ADD,
-                      fd_packet,
-                      &(struct epoll_event){
-                              .events = EPOLLIN,
-                              .data = { .u32 = N_DHCP4_CLIENT_EPOLL_IO },
-                      });
-        if (r < 0)
-                return -errno;
+        r = n_dhcp4_os_poll_add(connection->fd_poll, fd_packet,
+                                N_DHCP4_CLIENT_EPOLL_IO);
+        if (r)
+                return r;
 
         connection->state = N_DHCP4_C_CONNECTION_STATE_PACKET;
         connection->fd_packet = fd_packet;
@@ -196,19 +189,14 @@
         if (r)
                 return r;
 
-        r = epoll_ctl(connection->fd_epoll,
-                      EPOLL_CTL_ADD,
-                      fd_udp,
-                      &(struct epoll_event){
-                              .events = EPOLLIN,
-                              .data = { .u32 = N_DHCP4_CLIENT_EPOLL_IO },
-                      });
-        if (r < 0)
-                return -errno;
+        r = n_dhcp4_os_poll_add(connection->fd_poll, fd_udp,
+                                N_DHCP4_CLIENT_EPOLL_IO);
+        if (r)
+                return r;
 
         r = packet_shutdown(connection->fd_packet);
         if (r < 0) {
-                epoll_ctl(connection->fd_epoll, EPOLL_CTL_DEL, fd_udp, NULL);
+                n_dhcp4_os_poll_del(connection->fd_poll, fd_udp);
                 return r;
         }
 
@@ -223,16 +211,16 @@
 
 void n_dhcp4_c_connection_close(NDhcp4CConnection *connection) {
         if (connection->fd_udp >= 0) {
-                epoll_ctl(connection->fd_epoll, EPOLL_CTL_DEL, connection->fd_udp, NULL);
+                n_dhcp4_os_poll_del(connection->fd_poll, connection->fd_udp);
                 connection->fd_udp = c_close(connection->fd_udp);
         }
 
         if (connection->fd_packet >= 0) {
-                epoll_ctl(connection->fd_epoll, EPOLL_CTL_DEL, connection->fd_packet, NULL);
+                n_dhcp4_os_poll_del(connection->fd_poll, connection->fd_packet);
                 connection->fd_packet = c_close(connection->fd_packet);
         }
 
-        connection->fd_epoll = -1;
+        connection->fd_poll = -1;
         connection->state = N_DHCP4_C_CONNECTION_STATE_CLOSED;
         connection->ns_drain_timeout = 0;
 }
@@ -1133,7 +1121,7 @@
         int r;
 
         if (connection->ns_drain_timeout != 0 && connection->ns_drain_timeout < timestamp) {
-                epoll_ctl(connection->fd_epoll, EPOLL_CTL_DEL, connection->fd_packet, NULL);
+                n_dhcp4_os_poll_del(connection->fd_poll, connection->fd_packet);
                 connection->fd_packet = c_close(connection->fd_packet);
                 connection->state = N_DHCP4_C_CONNECTION_STATE_UDP;
                 connection->ns_drain_timeout = 0;
@@ -1202,7 +1190,7 @@
                  * and drained, clean up the packet socket and fall through to
                  * dispatching the UDP socket.
                  */
-                r = epoll_ctl(connection->fd_epoll, EPOLL_CTL_DEL, connection->fd_packet, NULL);
+                r = n_dhcp4_os_poll_del(connection->fd_poll, connection->fd_packet);
                 c_assert(!r);
                 connection->fd_packet = c_close(connection->fd_packet);
                 connection->state = N_DHCP4_C_CONNECTION_STATE_UDP;
