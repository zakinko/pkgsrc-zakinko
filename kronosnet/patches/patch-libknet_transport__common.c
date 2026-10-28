$NetBSD$

Two differences between Linux and the BSDs in socket setup.

Linux caps SO_RCVBUF and SO_SNDBUF requests above its maximum and
succeeds.  NetBSD refuses them with ENOBUFS (the limit is kern.sbmax,
256 KB by default, against knet's 8 MB) and leaves the buffer at its
default.  libknet treated that as fatal, so no handle could be created;
and simply carrying on is not enough either, because the default send
buffer of a local datagram socket is 2560 bytes, smaller than a packet,
and knet_send() then fails with EMSGSIZE.  Halve the request until it is
accepted, and let the existing check report the cap.

IP_BINDANY, which the BSD build sets where Linux sets IP_FREEBIND, needs
privilege on NetBSD and FreeBSD; IP_FREEBIND does not.  Without it the
socket can still bind an address that is already configured, so carry on
with a warning on EPERM rather than failing the link.

--- libknet/transport_common.c.orig
+++ libknet/transport_common.c
@@ -100,8 +100,21 @@
 	int savederrno = 0;
 	int new_value;
 	socklen_t value_len = sizeof new_value;
+	int request = target;
+	int res;
 
-	if (setsockopt(sock, SOL_SOCKET, option, &target, sizeof target) != 0) {
+	/*
+	 * Linux caps a size above its maximum and succeeds; the BSDs refuse
+	 * it with ENOBUFS (kern.sbmax on NetBSD) and leave the buffer at its
+	 * default, which for a local datagram socket is smaller than one
+	 * packet.  Halve the request until it is accepted, so the buffer is
+	 * as large as allowed, and let the check below report the cap.
+	 */
+	while (((res = setsockopt(sock, SOL_SOCKET, option, &request, sizeof request)) != 0) &&
+	       (errno == ENOBUFS) && (request > 1)) {
+		request /= 2;
+	}
+	if (res != 0) {
 		savederrno = errno;
 		log_err(knet_h, KNET_SUB_TRANSPORT,
 			"Error setting socket buffer via option %d to value %d: %s\n",
@@ -281,14 +294,25 @@
 #ifdef KNET_BSD
 #ifdef IP_BINDANY /* BSD */
 	value = 1;
+	/*
+	 * Unlike Linux's IP_FREEBIND, IP_BINDANY needs privilege.  Without
+	 * it the socket can still bind an address that is already up, as
+	 * on a platform without the option at all.
+	 */
 	if (setsockopt(sock, IPPROTO_IP, IP_BINDANY, &value, sizeof(value)) <0) {
 		savederrno = errno;
-		err = -1;
-		log_err(knet_h, KNET_SUB_TRANSPORT, "Unable to set BINDANY on %s socket: %s",
-			type, strerror(savederrno));
-		goto exit_error;
+		if (savederrno != EPERM) {
+			err = -1;
+			log_err(knet_h, KNET_SUB_TRANSPORT, "Unable to set BINDANY on %s socket: %s",
+				type, strerror(savederrno));
+			goto exit_error;
+		}
+		savederrno = 0;
+		log_warn(knet_h, KNET_SUB_TRANSPORT, "BINDANY not permitted on %s socket %i;"
+			 " only addresses already configured can be bound", type, sock);
+	} else {
+		log_debug(knet_h, KNET_SUB_TRANSPORT, "BINDANY enabled on socket: %i", sock);
 	}
-	log_debug(knet_h, KNET_SUB_TRANSPORT, "BINDANY enabled on socket: %i", sock);
 #else
 	log_debug(knet_h, KNET_SUB_TRANSPORT, "BINDANY not available in this build/platform");
 #endif
