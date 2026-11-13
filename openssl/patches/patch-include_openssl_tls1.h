$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- include/openssl/tls1.h.orig
+++ include/openssl/tls1.h
@@ -160,6 +160,13 @@ extern "C" {
 #define TLSEXT_TYPE_post_handshake_auth 49
 #define TLSEXT_TYPE_signature_algorithms_cert 50
 #define TLSEXT_TYPE_key_share 51
+
+/* ExtensionType value from RFC9146 */
+#define TLSEXT_TYPE_connection_id 54
+
+/* ExtensionType value from RFC9853 */
+#define TLSEXT_TYPE_rrc 61
+
 #define TLSEXT_TYPE_quic_transport_parameters 57
 
 /* Temporary extension type */
