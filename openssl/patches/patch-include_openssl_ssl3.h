$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- include/openssl/ssl3.h.orig
+++ include/openssl/ssl3.h
@@ -218,7 +218,9 @@ extern "C" {
 #define SSL3_RT_ALERT 21
 #define SSL3_RT_HANDSHAKE 22
 #define SSL3_RT_APPLICATION_DATA 23
+#define SSL3_RT_TLS12_CID 25 /* RFC 9146 */
 #define SSL3_RT_ACK 26 /* RFC 9147 */
+#define SSL3_RT_RETURN_ROUTABILITY_CHECK 27 /* RFC 9853 */
 
 /* Pseudo content types to indicate additional parameters */
 #define TLS1_RT_CRYPTO 0x1000
@@ -314,6 +316,9 @@ extern "C" {
 #define SSL3_MT_NEWSESSION_TICKET 4
 #define SSL3_MT_END_OF_EARLY_DATA 5
 #define SSL3_MT_ENCRYPTED_EXTENSIONS 8
+/* RFC 9147 section 5.2, DTLS 1.3 only */
+#define SSL3_MT_REQUEST_CONNECTION_ID 9
+#define SSL3_MT_NEW_CONNECTION_ID 10
 #define SSL3_MT_CERTIFICATE 11
 #define SSL3_MT_SERVER_KEY_EXCHANGE 12
 #define SSL3_MT_CERTIFICATE_REQUEST 13
