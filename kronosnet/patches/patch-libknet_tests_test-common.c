$NetBSD$

Bound payload_len in the test helper inject_packet().  The packet length
is the header plus payload_len, unbounded, and gcc 12 with NetBSD's
_FORTIFY_SOURCE memset() wrapper stops the -Werror build on it.

--- libknet/tests/test-common.c.orig
+++ libknet/tests/test-common.c
@@ -1029,6 +1029,11 @@
 	socklen_t addrlen;
 	struct timespec timestamp;
 
+	if (payload_len > KNET_MAX_PACKET_SIZE) {
+		errno = EINVAL;
+		return -1;
+	}
+
 	/* Determine packet size based on type */
 	switch (packet_type) {
 	case KNET_HEADER_TYPE_DATA:
