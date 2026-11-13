$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/statem/extensions.c.orig
+++ ssl/statem/extensions.c
@@ -87,6 +87,8 @@ static int init_srp(SSL_CONNECTION *s, unsigned int context);
 #endif
 static int init_ec_point_formats(SSL_CONNECTION *s, unsigned int context);
 static int init_etm(SSL_CONNECTION *s, unsigned int context);
+static int init_connection_id(SSL_CONNECTION *s, unsigned int context);
+static int init_rrc(SSL_CONNECTION *s, unsigned int context);
 static int init_ems(SSL_CONNECTION *s, unsigned int context);
 static int final_ems(SSL_CONNECTION *s, unsigned int context, int sent);
 static int init_psk_kex_modes(SSL_CONNECTION *s, unsigned int context);
@@ -315,6 +317,30 @@ static const EXTENSION_DEFINITION ext_defs[] = {
         OSSL_ECH_HANDLING_COMPRESS,
         init_etm, tls_parse_ctos_etm, tls_parse_stoc_etm,
         tls_construct_stoc_etm, tls_construct_ctos_etm, NULL },
+    /*
+     * RFC 9146 section 3: ClientHello and ServerHello, DTLS only; in DTLS
+     * 1.3 the same (RFC 9147 section 9.1, "The "connection_id" extension,
+     * which is used in ClientHello and ServerHello messages, is defined in
+     * [RFC9146]").  It must come after encrypt_then_mac, whose outcome
+     * tls_dtls_cid_record_protection_ok() depends on.
+     */
+    { TLSEXT_TYPE_connection_id,
+        SSL_EXT_CLIENT_HELLO | SSL_EXT_TLS1_2_SERVER_HELLO
+            | SSL_EXT_TLS1_3_SERVER_HELLO | SSL_EXT_DTLS_ONLY,
+        OSSL_ECH_HANDLING_COMPRESS,
+        init_connection_id, tls_parse_ctos_connection_id,
+        tls_parse_stoc_connection_id, tls_construct_stoc_connection_id,
+        tls_construct_ctos_connection_id, NULL },
+    /*
+     * RFC 9853 section 3: ClientHello and ServerHello, DTLS only.  It must
+     * come after connection_id, which the server's answer depends on.
+     */
+    { TLSEXT_TYPE_rrc,
+        SSL_EXT_CLIENT_HELLO | SSL_EXT_TLS1_2_SERVER_HELLO
+            | SSL_EXT_TLS1_3_SERVER_HELLO | SSL_EXT_DTLS_ONLY,
+        OSSL_ECH_HANDLING_COMPRESS,
+        init_rrc, tls_parse_ctos_rrc, tls_parse_stoc_rrc,
+        tls_construct_stoc_rrc, tls_construct_ctos_rrc, NULL },
 #ifndef OPENSSL_NO_CT
     { TLSEXT_TYPE_signed_certificate_timestamp,
         SSL_EXT_CLIENT_HELLO | SSL_EXT_TLS1_2_SERVER_HELLO
@@ -1581,6 +1607,153 @@ static int init_etm(SSL_CONNECTION *s, unsigned int context)
     return 1;
 }
 
+/*
+ * RFC 9146 section 3: "When a DTLS session is resumed or renegotiated, the
+ * "connection_id" extension is negotiated afresh."  The client runs this when
+ * it reads the ServerHello, after its ClientHello has gone out, so the CID it
+ * sent (|sent|) is left alone here and replaced only when the next
+ * ClientHello is built.
+ */
+static int init_connection_id(SSL_CONNECTION *s, unsigned int context)
+{
+    s->ext.dtls_cid.received = 0;
+    s->ext.dtls_cid.negotiated = 0;
+    s->ext.dtls_cid.spares_num = 0;
+    s->ext.dtls_cid.ncid_pending = 0;
+    s->ext.dtls_cid.rcid_num = 0;
+    s->ext.dtls_cid.rcid_unfulfilled = 0;
+    OPENSSL_free(s->ext.dtls_cid.peer);
+    s->ext.dtls_cid.peer = NULL;
+    s->ext.dtls_cid.peer_len = 0;
+
+    return 1;
+}
+
+/* RFC 9853 section 3: negotiated afresh with the "connection_id" extension */
+static int init_rrc(SSL_CONNECTION *s, unsigned int context)
+{
+    s->ext.dtls_cid.rrc_received = 0;
+    s->ext.dtls_cid.rrc_negotiated = 0;
+
+    return 1;
+}
+
+/*
+ * Record the CID that goes out in our "connection_id" extension.  It is the
+ * CID the record layer of the next epoch expects in the records it reads.
+ */
+int tls_dtls_cid_set_sent(SSL_CONNECTION *s)
+{
+    unsigned char *sent = NULL;
+
+    if (s->ext.dtls_cid.own_len != 0
+        && (sent = OPENSSL_memdup(s->ext.dtls_cid.own,
+                s->ext.dtls_cid.own_len))
+            == NULL)
+        return 0;
+
+    OPENSSL_free(s->ext.dtls_cid.sent);
+    s->ext.dtls_cid.sent = sent;
+    s->ext.dtls_cid.sent_len = s->ext.dtls_cid.own_len;
+    return 1;
+}
+
+/*
+ * Parse the ConnectionId structure of a "connection_id" extension into
+ * |peer|.  RFC 9146 section 3:
+ *
+ *     struct {
+ *         opaque cid<0..2^8-1>;
+ *     } ConnectionId;
+ */
+int tls_dtls_cid_parse(SSL_CONNECTION *s, PACKET *pkt)
+{
+    PACKET cid;
+    unsigned char *peer = NULL;
+    size_t peer_len = 0;
+
+    if (!PACKET_get_length_prefixed_1(pkt, &cid)
+        || PACKET_remaining(pkt) != 0) {
+        SSLfatal(s, SSL_AD_DECODE_ERROR, SSL_R_BAD_EXTENSION);
+        return 0;
+    }
+    if (PACKET_remaining(&cid) != 0
+        && !PACKET_memdup(&cid, &peer, &peer_len)) {
+        SSLfatal(s, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+        return 0;
+    }
+
+    OPENSSL_free(s->ext.dtls_cid.peer);
+    s->ext.dtls_cid.peer = peer;
+    s->ext.dtls_cid.peer_len = peer_len;
+    s->ext.dtls_cid.received = 1;
+    return 1;
+}
+
+/*
+ * Write a "connection_id" extension carrying |own|, the CID we want to
+ * receive (RFC 9146 section 3), and remember it as the CID that was sent.
+ */
+int tls_dtls_cid_construct(SSL_CONNECTION *s, WPACKET *pkt)
+{
+    OSSL_PARAM params[2];
+
+    if (!tls_dtls_cid_set_sent(s)
+        || !WPACKET_put_bytes_u16(pkt, TLSEXT_TYPE_connection_id)
+        || !WPACKET_start_sub_packet_u16(pkt)
+        || !WPACKET_sub_memcpy_u8(pkt, s->ext.dtls_cid.sent,
+            s->ext.dtls_cid.sent_len)
+        || !WPACKET_close(pkt)) {
+        SSLfatal(s, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+        return 0;
+    }
+
+    /*
+     * The current read record layer predates the CID.  In DTLS 1.3 it reads
+     * ahead the records of the next epoch, which carry this CID if the peer
+     * accepts it (RFC 9147 section 9.1), and has to find where they end.
+     */
+    if (s->ext.dtls_cid.sent_len != 0 && s->rlayer.rrlmethod != NULL
+        && s->rlayer.rrlmethod->set_options != NULL
+        && s->rlayer.rrl != NULL) {
+        params[0] = OSSL_PARAM_construct_octet_string(OSSL_LIBSSL_RECORD_LAYER_PARAM_DTLS_CID,
+            s->ext.dtls_cid.sent, s->ext.dtls_cid.sent_len);
+        params[1] = OSSL_PARAM_construct_end();
+        if (!s->rlayer.rrlmethod->set_options(s->rlayer.rrl, params)) {
+            SSLfatal(s, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+            return 0;
+        }
+    }
+    return 1;
+}
+
+/*
+ * RFC 9146 section 5 changes the MAC input for block ciphers with and without
+ * Encrypt-then-MAC (5.1, 5.2) and the additional data for AEAD ciphers (5.3).
+ * Sections 5.2 and 5.3 are implemented.  Section 5.1 is not: the receiving
+ * side of a MAC-then-encrypt record has to compute the MAC in constant time
+ * (Lucky 13), and the code that does so, ssl3_cbc_digest_record() through the
+ * "tls-data-size" parameter of the HMAC provider, takes a fixed 13 byte
+ * header.  The RFC lets a server decline the extension (section 3, "A server
+ * willing to use CIDs will respond"), so the extension is only used with a
+ * record protection for which it is implemented.  This is a choice of this
+ * implementation, not a requirement of RFC 9146.
+ */
+int tls_dtls_cid_record_protection_ok(const SSL_CONNECTION *s)
+{
+    const SSL_CIPHER *c = s->s3.tmp.new_cipher;
+
+    if (c == NULL)
+        return 0;
+    /* GCM, CCM, ChaCha20-Poly1305: RFC 9146 section 5.3 */
+    if (c->algorithm_mac == SSL_AEAD)
+        return 1;
+    /* CBC with Encrypt-then-MAC (RFC 7366): RFC 9146 section 5.2 */
+    if (s->ext.use_etm)
+        return 1;
+    return 0;
+}
+
 static int init_ems(SSL_CONNECTION *s, unsigned int context)
 {
     if (s->s3.flags & TLS1_FLAGS_RECEIVED_EXTMS) {
