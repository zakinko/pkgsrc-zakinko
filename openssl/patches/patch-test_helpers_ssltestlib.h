$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- test/helpers/ssltestlib.h.orig
+++ test/helpers/ssltestlib.h
@@ -74,6 +74,12 @@ void bio_s_no_retry_zero_free(void);
 #define MEMPACKET_CTRL_SET_DROP_REC (2 << 15)
 #define MEMPACKET_CTRL_GET_DROP_REC (3 << 15)
 #define MEMPACKET_CTRL_SET_DUPLICATE_REC (4 << 15)
+/*
+ * The length of the CID in the DTLS 1.2 tls12_cid records (RFC 9146) passing
+ * through the BIO.  It is not on the wire, and the BIO needs it to find the
+ * length field of such a record.
+ */
+#define MEMPACKET_CTRL_SET_CID_LEN (5 << 15)
 
 int mempacket_swap_epoch(BIO *bio);
 int mempacket_swap_epoch_dtls13(BIO *bio);
