$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/statem/extensions_srvr.c.orig
+++ ssl/statem/extensions_srvr.c
@@ -554,6 +554,35 @@ int tls_parse_ctos_etm(SSL_CONNECTION *s, PACKET *pkt, unsigned int context,
     return 1;
 }
 
+/*
+ * A "connection_id" extension in the ClientHello names the CID the client
+ * wants to receive (RFC 9146 section 3).  It is only remembered here; whether
+ * it is accepted is decided in tls_construct_stoc_connection_id(), once the
+ * cipher and Encrypt-then-MAC are known.
+ */
+int tls_parse_ctos_connection_id(SSL_CONNECTION *s, PACKET *pkt,
+    unsigned int context,
+    X509 *x, size_t chainidx)
+{
+    if (!s->ext.dtls_cid.enabled)
+        return 1;
+
+    return tls_dtls_cid_parse(s, pkt);
+}
+
+/* RFC 9853 section 3: "the extension_data field of this extension is empty" */
+int tls_parse_ctos_rrc(SSL_CONNECTION *s, PACKET *pkt, unsigned int context,
+    X509 *x, size_t chainidx)
+{
+    if (PACKET_remaining(pkt) != 0) {
+        SSLfatal(s, SSL_AD_DECODE_ERROR, SSL_R_BAD_EXTENSION);
+        return 0;
+    }
+    if (s->ext.dtls_cid.enabled && !s->ext.dtls_cid.rrc_disabled)
+        s->ext.dtls_cid.rrc_received = 1;
+    return 1;
+}
+
 /*
  * Process a psk_kex_modes extension received in the ClientHello. |pkt| contains
  * the raw PACKET data for the extension. Returns 1 on success or 0 on failure.
@@ -2015,6 +2044,51 @@ EXT_RETURN tls_construct_stoc_etm(SSL_CONNECTION *s, WPACKET *pkt,
     return EXT_RETURN_SENT;
 }
 
+/*
+ * RFC 9146 section 3: "A server willing to use CIDs will respond with a
+ * "connection_id" extension in the ServerHello, containing the CID it wishes
+ * the client to use when sending messages towards it."  Not responding is how
+ * the server declines.
+ */
+EXT_RETURN tls_construct_stoc_connection_id(SSL_CONNECTION *s, WPACKET *pkt,
+    unsigned int context,
+    X509 *x, size_t chainidx)
+{
+    if (!s->ext.dtls_cid.enabled || !s->ext.dtls_cid.received
+        || !tls_dtls_cid_record_protection_ok(s))
+        return EXT_RETURN_NOT_SENT;
+
+    if (!tls_dtls_cid_construct(s, pkt)) {
+        /* SSLfatal() already called */
+        return EXT_RETURN_FAIL;
+    }
+
+    s->ext.dtls_cid.negotiated = 1;
+    return EXT_RETURN_SENT;
+}
+
+/*
+ * RFC 9853 section 3: "If the client includes the rrc extension in its
+ * ClientHello but omits the connection_id extension, the server MUST NOT
+ * include the rrc extension in its ServerHello."  The CID being negotiated
+ * implies the client sent connection_id.
+ */
+EXT_RETURN tls_construct_stoc_rrc(SSL_CONNECTION *s, WPACKET *pkt,
+    unsigned int context, X509 *x, size_t chainidx)
+{
+    if (!s->ext.dtls_cid.rrc_received || !s->ext.dtls_cid.negotiated)
+        return EXT_RETURN_NOT_SENT;
+
+    if (!WPACKET_put_bytes_u16(pkt, TLSEXT_TYPE_rrc)
+        || !WPACKET_put_bytes_u16(pkt, 0)) {
+        SSLfatal(s, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+        return EXT_RETURN_FAIL;
+    }
+
+    s->ext.dtls_cid.rrc_negotiated = 1;
+    return EXT_RETURN_SENT;
+}
+
 EXT_RETURN tls_construct_stoc_ems(SSL_CONNECTION *s, WPACKET *pkt,
     unsigned int context,
     X509 *x, size_t chainidx)
