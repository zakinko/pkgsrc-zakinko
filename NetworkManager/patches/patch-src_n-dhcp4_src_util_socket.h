$NetBSD$

Drop a declaration that needed a Linux header.

socket_SIOCGIFNAME() is a step inside the Linux implementation of
socket_bind_if() - turning an index into a name for SO_BINDTODEVICE - and
nothing else ever called it, so it is static there now.  Declaring it here also
meant this header needed IFNAMSIZ, and with it an include that does not exist
everywhere.

--- src/n-dhcp4/src/util/socket.h.orig
+++ src/n-dhcp4/src/util/socket.h
@@ -7,5 +7,11 @@
 #include <c-stdaux.h>
 #include <stdlib.h>
 
-int socket_SIOCGIFNAME(int socket, int ifindex, char (*ifnamep)[IFNAMSIZ]);
+/*
+ * socket_SIOCGIFNAME() used to be declared here.  It is a step inside the
+ * Linux implementation of socket_bind_if() - turning an index into a name for
+ * SO_BINDTODEVICE - and nothing else ever called it, so it is static there
+ * now.  Declaring it here also meant this header needed IFNAMSIZ, and with it
+ * an include that only exists on Linux.
+ */
 int socket_bind_if(int socket, int ifindex);
