$NetBSD$

Compute the fragment buffer sizes in integers.

ceil((float)a / b) for positive integers is (a + b - 1) / b.  Through the
float conversion gcc 12 cannot bound the result, and with NetBSD's
_FORTIFY_SOURCE memset() wrapper the -Werror build stops with a
stringop-overflow error on the memset() that follows each malloc().

--- libknet/handle.c.orig
+++ libknet/handle.c
@@ -161,7 +161,7 @@
 	size_t bufsize;
 
 	for (i = 0; i < PCKT_FRAG_MAX; i++) {
-		bufsize = ceil((float)KNET_MAX_PACKET_SIZE / (i + 1)) + KNET_HEADER_ALL_SIZE;
+		bufsize = (KNET_MAX_PACKET_SIZE + i) / (i + 1) + KNET_HEADER_ALL_SIZE;
 		knet_h->send_to_links_buf[i] = malloc(bufsize);
 		if (!knet_h->send_to_links_buf[i]) {
 			savederrno = errno;
@@ -211,7 +211,7 @@
 	memset(knet_h->pmtudbuf, 0, KNET_PMTUD_SIZE_V6 + KNET_HEADER_ALL_SIZE);
 
 	for (i = 0; i < PCKT_FRAG_MAX; i++) {
-		bufsize = ceil((float)KNET_MAX_PACKET_SIZE / (i + 1)) + KNET_HEADER_ALL_SIZE + KNET_DATABUFSIZE_CRYPT_PAD;
+		bufsize = (KNET_MAX_PACKET_SIZE + i) / (i + 1) + KNET_HEADER_ALL_SIZE + KNET_DATABUFSIZE_CRYPT_PAD;
 		knet_h->send_to_links_buf_crypt[i] = malloc(bufsize);
 		if (!knet_h->send_to_links_buf_crypt[i]) {
 			savederrno = errno;
