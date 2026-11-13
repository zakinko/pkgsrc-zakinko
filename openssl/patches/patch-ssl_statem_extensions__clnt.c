$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/statem/extensions_clnt.c.orig
+++ ssl/statem/extensions_clnt.c
@@ -700,6 +700,53 @@ EXT_RETURN tls_construct_ctos_etm(SSL_CONNECTION *s, WPACKET *pkt,
     return EXT_RETURN_SENT;
 }
 
+/*
+ * RFC 9146 section 3: "The extension_data field of this extension, when
+ * included in the ClientHello, MUST contain the ConnectionId structure."
+ */
+EXT_RETURN tls_construct_ctos_connection_id(SSL_CONNECTION *s, WPACKET *pkt,
+    unsigned int context,
+    X509 *x, size_t chainidx)
+{
+    if (!s->ext.dtls_cid.enabled)
+        return EXT_RETURN_NOT_SENT;
+#ifndef OPENSSL_NO_ECH
+    ECH_SAME_EXT(s, context, pkt)
+#endif
+
+    if (!tls_dtls_cid_construct(s, pkt)) {
+        /* SSLfatal() already called */
+        return EXT_RETURN_FAIL;
+    }
+
+    return EXT_RETURN_SENT;
+}
+
+/*
+ * RFC 9853 section 3: "A client offering the rrc extension MUST also offer
+ * the connection_id extension", and "A client offering the connection_id
+ * extension SHOULD also offer the rrc extension, unless the application
+ * using DTLS has its own address validation mechanism."  The extension data
+ * is empty.
+ */
+EXT_RETURN tls_construct_ctos_rrc(SSL_CONNECTION *s, WPACKET *pkt,
+    unsigned int context, X509 *x, size_t chainidx)
+{
+    if (!s->ext.dtls_cid.enabled || s->ext.dtls_cid.rrc_disabled)
+        return EXT_RETURN_NOT_SENT;
+#ifndef OPENSSL_NO_ECH
+    ECH_SAME_EXT(s, context, pkt)
+#endif
+
+    if (!WPACKET_put_bytes_u16(pkt, TLSEXT_TYPE_rrc)
+        || !WPACKET_put_bytes_u16(pkt, 0)) {
+        SSLfatal(s, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+        return EXT_RETURN_FAIL;
+    }
+
+    return EXT_RETURN_SENT;
+}
+
 #ifndef OPENSSL_NO_CT
 EXT_RETURN tls_construct_ctos_sct(SSL_CONNECTION *s, WPACKET *pkt,
     unsigned int context,
@@ -2143,6 +2190,50 @@ int tls_parse_stoc_etm(SSL_CONNECTION *s, PACKET *pkt, unsigned int context,
     return 1;
 }
 
+/*
+ * The server sent a "connection_id" extension, which it only does in answer
+ * to ours (RFC 9146 section 3; an unsolicited one has already been refused by
+ * tls_collect_extensions()).  It names the CID the server wants to receive,
+ * so it is the one we put in the records we send.
+ */
+int tls_parse_stoc_connection_id(SSL_CONNECTION *s, PACKET *pkt,
+    unsigned int context,
+    X509 *x, size_t chainidx)
+{
+    if (!tls_dtls_cid_parse(s, pkt)) {
+        /* SSLfatal() already called */
+        return 0;
+    }
+
+    /*
+     * The server accepted with a record protection whose CID form is not
+     * implemented here: see tls_dtls_cid_record_protection_ok().
+     */
+    if (!tls_dtls_cid_record_protection_ok(s)) {
+        SSLfatal(s, SSL_AD_HANDSHAKE_FAILURE,
+            SSL_R_CONNECTION_ID_NOT_SUPPORTED_WITH_CIPHER);
+        return 0;
+    }
+
+    s->ext.dtls_cid.negotiated = 1;
+    return 1;
+}
+
+/*
+ * The server answered our "rrc" extension (RFC 9853 section 3).  "The
+ * extension_data field of this extension is empty."
+ */
+int tls_parse_stoc_rrc(SSL_CONNECTION *s, PACKET *pkt, unsigned int context,
+    X509 *x, size_t chainidx)
+{
+    if (PACKET_remaining(pkt) != 0) {
+        SSLfatal(s, SSL_AD_DECODE_ERROR, SSL_R_BAD_EXTENSION);
+        return 0;
+    }
+    s->ext.dtls_cid.rrc_negotiated = 1;
+    return 1;
+}
+
 int tls_parse_stoc_ems(SSL_CONNECTION *s, PACKET *pkt, unsigned int context,
     X509 *x, size_t chainidx)
 {
