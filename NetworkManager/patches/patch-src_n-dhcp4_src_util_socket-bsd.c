$NetBSD$

The BSD half of the socket helpers.

New file.  There is no SO_BINDTODEVICE here, and both callers already pin the
socket harder than it would: each binds to a specific local address and
connects to a specific peer immediately afterwards, so the kernel delivers only
that conversation.  The device binding was a second lock on the same door.

It is not being silently skipped for the raw path either: the raw path here is
a BPF device, bound to its interface by BIOCSETIF while it is opened, and it
never reaches this function.

--- src/n-dhcp4/src/util/socket-bsd.c.orig
+++ src/n-dhcp4/src/util/socket-bsd.c
@@ -0,0 +1,91 @@
+/*
+ * Socket Helpers - the BSDs
+ *
+ * There is no SO_BINDTODEVICE here, and no ioctl that turns an interface index
+ * into a name on an arbitrary socket either - if_indextoname() does that, but
+ * nothing in this file needs it any more.
+ */
+
+#include <c-stdaux.h>
+#include <errno.h>
+#include <net/if.h>
+#include <netinet/in.h>
+#include <sys/uio.h>
+#include <stddef.h>
+#include <string.h>
+#include <sys/ioctl.h>
+#include <sys/socket.h>
+#include <sys/types.h>
+#include "socket.h"
+
+/**
+ * socket_bind_if() - bind socket to a network interface
+ * @socket:                     socket to operate on
+ * @ifindex:                    index of network interface to bind to, or 0
+ *
+ * The BSDs have no way to pin a UDP socket to an interface the way
+ * SO_BINDTODEVICE does, and both callers already pin the socket harder than
+ * that: each one binds to a specific local address and connects to a specific
+ * peer immediately afterwards, so the kernel delivers only that conversation.
+ * The device binding was a second lock on the same door.
+ *
+ * It is not silently skipped for the raw path, because the raw path here is a
+ * BPF device, which is bound to its interface by BIOCSETIF while it is opened
+ * and never reaches this function.
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+int socket_bind_if(int socket, int ifindex) {
+        c_assert(ifindex >= 0);
+
+        (void)socket;
+        (void)ifindex;
+
+        return 0;
+}
+
+/**
+ * socket_udp_send_from() - send one datagram with a chosen source address
+ * @socket:                     bound UDP socket
+ * @src:                        address to send from
+ * @dest:                       address to send to
+ * @data:                       payload
+ * @n_data:                     length of @data
+ *
+ * The BSDs carry the source address as a bare struct in_addr attached with
+ * IP_SENDSRCADDR.  There is no in_pktinfo to fill in; the address is the
+ * whole of the control message.
+ *
+ * Return: bytes sent, or -1 with errno set.
+ */
+ssize_t socket_udp_send_from(int socket,
+                             const struct in_addr *src,
+                             const struct sockaddr_in *dest,
+                             const void *data,
+                             size_t n_data) {
+        struct iovec iov = {
+                .iov_base = (void *)data,
+                .iov_len = n_data,
+        };
+        union {
+                struct cmsghdr align; /* ensure correct stack alignment */
+                char buf[CMSG_SPACE(sizeof(struct in_addr))];
+        } control = {};
+        struct msghdr msg = {
+                .msg_name = (void *)dest,
+                .msg_namelen = sizeof(*dest),
+                .msg_iov = &iov,
+                .msg_iovlen = 1,
+                .msg_control = control.buf,
+                .msg_controllen = sizeof(control.buf),
+        };
+        struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
+        struct in_addr addr = *src;
+
+        cmsg->cmsg_level = IPPROTO_IP;
+        cmsg->cmsg_type = IP_SENDSRCADDR;
+        cmsg->cmsg_len = CMSG_LEN(sizeof(struct in_addr));
+        memcpy(CMSG_DATA(cmsg), &addr, sizeof(addr));
+
+        return sendmsg(socket, &msg, 0);
+}
