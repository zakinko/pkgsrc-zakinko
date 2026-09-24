$NetBSD$

Drop a declaration that needed a Linux header.

socket_SIOCGIFNAME() is a step inside the Linux implementation of
socket_bind_if() - turning an index into a name for SO_BINDTODEVICE - and
nothing else ever called it, so it is static there now.  Declaring it here also
meant this header needed IFNAMSIZ, and with it an include that does not exist
everywhere.

--- src/n-dhcp4/src/util/socket.h.orig
+++ src/n-dhcp4/src/util/socket.h
@@ -5,7 +5,39 @@
  */
 
 #include <c-stdaux.h>
+#include <netinet/in.h>
 #include <stdlib.h>
+#include <sys/socket.h>
+#include <sys/types.h>
 
-int socket_SIOCGIFNAME(int socket, int ifindex, char (*ifnamep)[IFNAMSIZ]);
+/*
+ * socket_SIOCGIFNAME() used to be declared here.  It is a step inside the
+ * Linux implementation of socket_bind_if() - turning an index into a name for
+ * SO_BINDTODEVICE - and nothing else ever called it, so it is static there
+ * now.  Declaring it here also meant this header needed IFNAMSIZ, and with it
+ * an include that only exists on Linux.
+ */
 int socket_bind_if(int socket, int ifindex);
+
+/*
+ * socket_udp_send_from() - send one datagram with a chosen source address
+ * @socket:     bound UDP socket
+ * @src:        address to send from
+ * @dest:       address to send to
+ * @data:       payload
+ * @n_data:     length of @data
+ *
+ * A DHCP server answers from the address the client is being offered, which
+ * is not the address the socket is bound to, so the source has to be chosen
+ * per datagram.  Linux does this with IP_PKTINFO and struct in_pktinfo; the
+ * BSDs do it with IP_SENDSRCADDR and a bare struct in_addr.  Neither name
+ * exists on the other, so the call lives here and each platform answers it
+ * in its own file.
+ *
+ * Return: bytes sent, or -1 with errno set.
+ */
+ssize_t socket_udp_send_from(int socket,
+                             const struct in_addr *src,
+                             const struct sockaddr_in *dest,
+                             const void *data,
+                             size_t n_data);
