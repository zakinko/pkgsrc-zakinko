$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/statem/statem_local.h.orig
+++ ssl/statem/statem_local.h
@@ -35,6 +35,12 @@
 #define SERVER_KEY_EXCH_MAX_LENGTH 102400
 #define SERVER_HELLO_DONE_MAX_LENGTH 0
 #define KEY_UPDATE_MAX_LENGTH 1
+/*
+ * RFC 9147 section 9: "ConnectionId cids<0..2^16-1>; ConnectionIdUsage
+ * usage;" and "uint8 num_cids;"
+ */
+#define NEW_CONNECTION_ID_MAX_LENGTH (2 + 65535 + 1)
+#define REQUEST_CONNECTION_ID_MAX_LENGTH 1
 #define CCS_MAX_LENGTH 1
 #define ACK_MAX_LENGTH 65538
 
@@ -148,6 +154,43 @@ __owur CON_FUNC_RETURN tls_construct_finished(SSL_CONNECTION *s, WPACKET *pkt);
 __owur CON_FUNC_RETURN tls_construct_key_update(SSL_CONNECTION *s, WPACKET *pkt);
 __owur MSG_PROCESS_RETURN tls_process_key_update(SSL_CONNECTION *s,
     PACKET *pkt);
+
+/**
+ * @brief Write a DTLS 1.3 NewConnectionId message (RFC 9147 section 9).
+ * @param s the connection
+ * @param pkt the message body
+ * @returns CON_FUNC_SUCCESS or CON_FUNC_ERROR (SSLfatal() called)
+ */
+__owur CON_FUNC_RETURN tls_construct_new_connection_id(SSL_CONNECTION *s,
+    WPACKET *pkt);
+
+/**
+ * @brief Write a DTLS 1.3 RequestConnectionId message (RFC 9147 section 9).
+ * @param s the connection
+ * @param pkt the message body
+ * @returns CON_FUNC_SUCCESS or CON_FUNC_ERROR (SSLfatal() called)
+ */
+__owur CON_FUNC_RETURN tls_construct_request_connection_id(SSL_CONNECTION *s,
+    WPACKET *pkt);
+
+/**
+ * @brief Process a DTLS 1.3 NewConnectionId message (RFC 9147 section 9).
+ * @param s the connection
+ * @param pkt the message body
+ * @returns MSG_PROCESS_FINISHED_READING or MSG_PROCESS_ERROR
+ */
+__owur MSG_PROCESS_RETURN tls_process_new_connection_id(SSL_CONNECTION *s,
+    PACKET *pkt);
+
+/**
+ * @brief Process a DTLS 1.3 RequestConnectionId message (RFC 9147
+ * section 9).
+ * @param s the connection
+ * @param pkt the message body
+ * @returns MSG_PROCESS_FINISHED_READING or MSG_PROCESS_ERROR
+ */
+__owur MSG_PROCESS_RETURN tls_process_request_connection_id(SSL_CONNECTION *s,
+    PACKET *pkt);
 __owur WORK_STATE tls_finish_handshake(SSL_CONNECTION *s, WORK_STATE wst,
     int clearbufs, int stop);
 __owur WORK_STATE dtls_wait_for_dry(SSL_CONNECTION *s);
@@ -348,6 +391,66 @@ int tls_parse_ctos_use_srtp(SSL_CONNECTION *s, PACKET *pkt,
 #endif
 int tls_parse_ctos_etm(SSL_CONNECTION *s, PACKET *pkt, unsigned int context,
     X509 *x, size_t chainidx);
+/**
+ * @brief Remember the CID offered in a ClientHello "connection_id" extension
+ * (RFC 9146 section 3), if the extension is enabled on @p s.
+ * @param s the server connection
+ * @param pkt the extension data
+ * @param context the extension context
+ * @param x unused
+ * @param chainidx unused
+ * @returns 1 on success, 0 on error (SSLfatal() called)
+ */
+int tls_parse_ctos_connection_id(SSL_CONNECTION *s, PACKET *pkt,
+    unsigned int context, X509 *x, size_t chainidx);
+
+/**
+ * @brief Note an "rrc" extension in the ClientHello (RFC 9853 section 3).
+ * @param s the server connection
+ * @param pkt the extension data, which must be empty
+ * @param context the extension context
+ * @param x unused
+ * @param chainidx unused
+ * @returns 1 on success, 0 on error (SSLfatal() called)
+ */
+int tls_parse_ctos_rrc(SSL_CONNECTION *s, PACKET *pkt, unsigned int context,
+    X509 *x, size_t chainidx);
+
+/**
+ * @brief Answer the client's "rrc" extension (RFC 9853 section 3).
+ * @param s the server connection
+ * @param pkt the packet the extension is written into
+ * @param context the extension context
+ * @param x unused
+ * @param chainidx unused
+ * @returns EXT_RETURN_SENT, EXT_RETURN_NOT_SENT or EXT_RETURN_FAIL
+ */
+EXT_RETURN tls_construct_stoc_rrc(SSL_CONNECTION *s, WPACKET *pkt,
+    unsigned int context, X509 *x, size_t chainidx);
+
+/**
+ * @brief Offer the "rrc" extension (RFC 9853 section 3).
+ * @param s the client connection
+ * @param pkt the packet the extension is written into
+ * @param context the extension context
+ * @param x unused
+ * @param chainidx unused
+ * @returns EXT_RETURN_SENT, EXT_RETURN_NOT_SENT or EXT_RETURN_FAIL
+ */
+EXT_RETURN tls_construct_ctos_rrc(SSL_CONNECTION *s, WPACKET *pkt,
+    unsigned int context, X509 *x, size_t chainidx);
+
+/**
+ * @brief Take the server's "rrc" extension (RFC 9853 section 3).
+ * @param s the client connection
+ * @param pkt the extension data, which must be empty
+ * @param context the extension context
+ * @param x unused
+ * @param chainidx unused
+ * @returns 1 on success, 0 on error (SSLfatal() called)
+ */
+int tls_parse_stoc_rrc(SSL_CONNECTION *s, PACKET *pkt, unsigned int context,
+    X509 *x, size_t chainidx);
 int tls_parse_ctos_key_share(SSL_CONNECTION *s, PACKET *pkt,
     unsigned int context, X509 *x, size_t chainidx);
 int tls_parse_ctos_cookie(SSL_CONNECTION *s, PACKET *pkt, unsigned int context,
@@ -405,6 +508,19 @@ EXT_RETURN tls_construct_stoc_use_srtp(SSL_CONNECTION *s, WPACKET *pkt,
 EXT_RETURN tls_construct_stoc_etm(SSL_CONNECTION *s, WPACKET *pkt,
     unsigned int context,
     X509 *x, size_t chainidx);
+/**
+ * @brief Accept the client's "connection_id" extension in the ServerHello
+ * (RFC 9146 section 3) if it is enabled and the record protection allows it.
+ * @param s the server connection
+ * @param pkt the packet the extension is written into
+ * @param context the extension context
+ * @param x unused
+ * @param chainidx unused
+ * @returns EXT_RETURN_SENT, EXT_RETURN_NOT_SENT or EXT_RETURN_FAIL
+ */
+EXT_RETURN tls_construct_stoc_connection_id(SSL_CONNECTION *s, WPACKET *pkt,
+    unsigned int context,
+    X509 *x, size_t chainidx);
 EXT_RETURN tls_construct_stoc_ems(SSL_CONNECTION *s, WPACKET *pkt,
     unsigned int context,
     X509 *x, size_t chainidx);
@@ -481,6 +597,19 @@ EXT_RETURN tls_construct_ctos_use_srtp(SSL_CONNECTION *s, WPACKET *pkt,
 EXT_RETURN tls_construct_ctos_etm(SSL_CONNECTION *s, WPACKET *pkt,
     unsigned int context,
     X509 *x, size_t chainidx);
+/**
+ * @brief Offer the "connection_id" extension in the ClientHello (RFC 9146
+ * section 3) if it is enabled on @p s.
+ * @param s the client connection
+ * @param pkt the packet the extension is written into
+ * @param context the extension context
+ * @param x unused
+ * @param chainidx unused
+ * @returns EXT_RETURN_SENT, EXT_RETURN_NOT_SENT or EXT_RETURN_FAIL
+ */
+EXT_RETURN tls_construct_ctos_connection_id(SSL_CONNECTION *s, WPACKET *pkt,
+    unsigned int context,
+    X509 *x, size_t chainidx);
 #ifndef OPENSSL_NO_CT
 EXT_RETURN tls_construct_ctos_sct(SSL_CONNECTION *s, WPACKET *pkt,
     unsigned int context,
@@ -550,6 +679,53 @@ int tls_parse_stoc_use_srtp(SSL_CONNECTION *s, PACKET *pkt,
 #endif
 int tls_parse_stoc_etm(SSL_CONNECTION *s, PACKET *pkt, unsigned int context,
     X509 *x, size_t chainidx);
+/**
+ * @brief Take the server's answer to our "connection_id" extension (RFC 9146
+ * section 3).
+ * @param s the client connection
+ * @param pkt the extension data
+ * @param context the extension context
+ * @param x unused
+ * @param chainidx unused
+ * @returns 1 on success, 0 on error (SSLfatal() called)
+ */
+int tls_parse_stoc_connection_id(SSL_CONNECTION *s, PACKET *pkt,
+    unsigned int context, X509 *x, size_t chainidx);
+
+/**
+ * @brief Tell whether the negotiated record protection is one whose RFC 9146
+ * form is implemented: an AEAD cipher (section 5.3) or a CBC cipher with
+ * Encrypt-then-MAC (section 5.2).
+ * @param s the connection, with its cipher chosen
+ * @returns 1 if it is, 0 otherwise
+ */
+int tls_dtls_cid_record_protection_ok(const SSL_CONNECTION *s);
+
+/**
+ * @brief Record the CID that goes out in our "connection_id" extension, the
+ * one the record layer of the next epoch expects.
+ * @param s the connection
+ * @returns 1 on success, 0 on allocation failure
+ */
+int tls_dtls_cid_set_sent(SSL_CONNECTION *s);
+
+/**
+ * @brief Parse the ConnectionId structure of a "connection_id" extension
+ * (RFC 9146 section 3) into the peer's CID.
+ * @param s the connection
+ * @param pkt the extension data
+ * @returns 1 on success, 0 on error (SSLfatal() called)
+ */
+int tls_dtls_cid_parse(SSL_CONNECTION *s, PACKET *pkt);
+
+/**
+ * @brief Write a "connection_id" extension carrying the CID we want to
+ * receive (RFC 9146 section 3).
+ * @param s the connection
+ * @param pkt the packet the extension is written into
+ * @returns 1 on success, 0 on error (SSLfatal() called)
+ */
+int tls_dtls_cid_construct(SSL_CONNECTION *s, WPACKET *pkt);
 int tls_parse_stoc_ems(SSL_CONNECTION *s, PACKET *pkt, unsigned int context,
     X509 *x, size_t chainidx);
 int tls_parse_stoc_supported_versions(SSL_CONNECTION *s, PACKET *pkt,
