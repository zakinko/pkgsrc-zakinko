$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/ssl_lib.c.orig
+++ ssl/ssl_lib.c
@@ -686,6 +686,7 @@ int ossl_ssl_connection_reset(SSL *s)
                 /* The detached connection cannot unregister itself on free. */
                 ossl_dtls_listener_unregister_established_conn(saved_listener,
                     &saved_peer_addr);
+                ossl_dtls_listener_unregister_conn_cid(saved_listener, s);
                 ossl_crypto_mutex_lock(dl->mutex);
                 sc->listener_rx = NULL;
                 ossl_crypto_mutex_unlock(dl->mutex);
@@ -1636,6 +1637,10 @@ void ossl_ssl_connection_free(SSL *ssl)
     OPENSSL_free(s->ext.scts);
 #endif
     OPENSSL_free(s->ext.alpn);
+    OPENSSL_free(s->ext.dtls_cid.own);
+    OPENSSL_free(s->ext.dtls_cid.peer);
+    OPENSSL_free(s->ext.dtls_cid.sent);
+    OPENSSL_free(s->ext.dtls_cid.own_more);
     OPENSSL_free(s->ext.tls13_cookie);
     if (s->clienthello != NULL)
         OPENSSL_free(s->clienthello->pre_proc_exts);
@@ -4149,6 +4154,204 @@ void SSL_get0_alpn_protos(SSL *ssl, const unsigned char **protos,
         *protos_len = len;
 }
 
+/*
+ * SSL_set1_dtls_cid enables the DTLS 1.2 "connection_id" extension (RFC 9146)
+ * on |s| and sets the CID we want the peer to use when sending to us.  A
+ * zero length is allowed: it says that we will send with the peer's CID but do
+ * not want one in the records sent to us (RFC 9146 section 3).
+ */
+int SSL_set1_dtls_cid(SSL *s, const unsigned char *cid, size_t cid_len)
+{
+    SSL_CONNECTION *sc = SSL_CONNECTION_FROM_SSL(s);
+    unsigned char *own = NULL;
+
+    if (sc == NULL || !SSL_CONNECTION_IS_DTLS(sc)) {
+        ERR_raise(ERR_LIB_SSL, ERR_R_PASSED_INVALID_ARGUMENT);
+        return 0;
+    }
+    /* RFC 9146 section 3: opaque cid<0..2^8-1> */
+    if (cid_len > SSL_DTLS_CID_MAX_LEN || (cid == NULL && cid_len != 0)) {
+        ERR_raise(ERR_LIB_SSL, ERR_R_PASSED_INVALID_ARGUMENT);
+        return 0;
+    }
+    /*
+     * The CID sent in our extension is the one the record layer for the
+     * next epoch will expect, so it cannot change between the two.
+     */
+    if (SSL_in_init(s) && !SSL_in_before(s)) {
+        ERR_raise(ERR_LIB_SSL, ERR_R_SHOULD_NOT_HAVE_BEEN_CALLED);
+        return 0;
+    }
+#if !defined(OPENSSL_NO_SOCK)
+    /*
+     * A DTLS listener that routes by CID chose this connection's CID and
+     * finds it by that; another one would leave it unreachable.
+     */
+    if (sc->d1 != NULL && sc->d1->listener != NULL
+        && ossl_dtls_listener_cid_len(sc->d1->listener) != 0) {
+        ERR_raise(ERR_LIB_SSL, ERR_R_SHOULD_NOT_HAVE_BEEN_CALLED);
+        return 0;
+    }
+#endif
+
+    if (cid_len != 0 && (own = OPENSSL_memdup(cid, cid_len)) == NULL)
+        return 0;
+
+    OPENSSL_free(sc->ext.dtls_cid.own);
+    sc->ext.dtls_cid.own = own;
+    sc->ext.dtls_cid.own_len = cid_len;
+    sc->ext.dtls_cid.enabled = 1;
+    return 1;
+}
+
+/*
+ * SSL_clear_dtls_cid stops offering or accepting the "connection_id"
+ * extension from the next handshake on.  A CID already in use by the current
+ * epoch stays in use until the next handshake replaces the keys.
+ */
+void SSL_clear_dtls_cid(SSL *s)
+{
+    SSL_CONNECTION *sc = SSL_CONNECTION_FROM_SSL(s);
+
+    if (sc == NULL)
+        return;
+
+    OPENSSL_free(sc->ext.dtls_cid.own);
+    sc->ext.dtls_cid.own = NULL;
+    sc->ext.dtls_cid.own_len = 0;
+    sc->ext.dtls_cid.enabled = 0;
+}
+
+/*
+ * SSL_set_dtls_rrc turns the Return Routability Check (RFC 9853) on or off
+ * for the next handshake.  It is on by default: "A client offering the
+ * connection_id extension SHOULD also offer the rrc extension, unless the
+ * application using DTLS has its own address validation mechanism"
+ * (section 3).
+ */
+int SSL_set_dtls_rrc(SSL *s, int enable)
+{
+    SSL_CONNECTION *sc = SSL_CONNECTION_FROM_SSL(s);
+
+    if (sc == NULL || !SSL_CONNECTION_IS_DTLS(sc)) {
+        ERR_raise(ERR_LIB_SSL, ERR_R_PASSED_INVALID_ARGUMENT);
+        return 0;
+    }
+    sc->ext.dtls_cid.rrc_disabled = !enable;
+    return 1;
+}
+
+int SSL_get_dtls_rrc(const SSL *s)
+{
+    const SSL_CONNECTION *sc = SSL_CONNECTION_FROM_CONST_SSL(s);
+
+    return sc != NULL && sc->ext.dtls_cid.rrc_negotiated;
+}
+
+/*
+ * Checks common to the two DTLS 1.3 CID update messages: a DTLS 1.3
+ * connection past its handshake, with the CID negotiated, and no message of
+ * the same kind waiting ("implementations MUST NOT send KeyUpdate,
+ * NewConnectionId, or RequestConnectionId messages if an earlier message of
+ * the same type has not yet been acknowledged", RFC 9147 section 5.8.4).
+ */
+static SSL_CONNECTION *dtls_cid_update_conn(SSL *s)
+{
+    SSL_CONNECTION *sc = SSL_CONNECTION_FROM_SSL(s);
+
+    if (sc == NULL || !SSL_CONNECTION_IS_DTLS13(sc)) {
+        ERR_raise(ERR_LIB_SSL, SSL_R_WRONG_SSL_VERSION);
+        return NULL;
+    }
+    if (!SSL_is_init_finished(s)) {
+        ERR_raise(ERR_LIB_SSL, SSL_R_STILL_IN_INIT);
+        return NULL;
+    }
+    if (!sc->ext.dtls_cid.negotiated) {
+        ERR_raise(ERR_LIB_SSL, ERR_R_SHOULD_NOT_HAVE_BEEN_CALLED);
+        return NULL;
+    }
+    return sc;
+}
+
+/*
+ * Have a NewConnectionId or RequestConnectionId sent.  Only one flight of
+ * post-handshake messages is in the air at a time: while one still waits
+ * for its ACK (RFC 9147 section 7), the state machine sends the new message
+ * from TLS_ST_OK once that ACK has come.
+ */
+static void dtls_cid_update_kick(SSL_CONNECTION *sc)
+{
+    if (sc->statem.hand_state == TLS_ST_OK)
+        ossl_statem_set_in_init(sc, 1);
+}
+
+int SSL_dtls_new_connection_id(SSL *s, int usage)
+{
+    SSL_CONNECTION *sc = dtls_cid_update_conn(s);
+
+    if (sc == NULL)
+        return 0;
+    /*
+     * RFC 9147 section 9: not with "an empty CID" negotiated for receiving,
+     * and the usage is one of the two defined.
+     */
+    if (sc->ext.dtls_cid.sent_len == 0 || sc->ext.dtls_cid.ncid_pending
+        || (usage != SSL_DTLS_CID_IMMEDIATE && usage != SSL_DTLS_CID_SPARE)) {
+        ERR_raise(ERR_LIB_SSL, ERR_R_PASSED_INVALID_ARGUMENT);
+        return 0;
+    }
+    sc->ext.dtls_cid.ncid_pending = 1;
+    sc->ext.dtls_cid.ncid_usage = usage;
+    sc->ext.dtls_cid.ncid_num = 1;
+    dtls_cid_update_kick(sc);
+    return 1;
+}
+
+int SSL_dtls_request_connection_id(SSL *s, unsigned int num)
+{
+    SSL_CONNECTION *sc = dtls_cid_update_conn(s);
+
+    if (sc == NULL)
+        return 0;
+    /*
+     * RFC 9147 section 9: "uint8 num_cids", not "when sending an empty CID",
+     * and "Endpoints MUST NOT send a RequestConnectionId message when an
+     * existing request is still unfulfilled".
+     */
+    if (sc->ext.dtls_cid.peer_len == 0 || sc->ext.dtls_cid.rcid_num != 0
+        || sc->ext.dtls_cid.rcid_unfulfilled || num == 0 || num > 255) {
+        ERR_raise(ERR_LIB_SSL, ERR_R_PASSED_INVALID_ARGUMENT);
+        return 0;
+    }
+    sc->ext.dtls_cid.rcid_num = num;
+    dtls_cid_update_kick(sc);
+    return 1;
+}
+
+/*
+ * SSL_get0_dtls_cid returns 1 if the "connection_id" extension was negotiated
+ * in the last handshake, and 0 otherwise.  |own| is the CID in the records we
+ * receive and |peer| the CID in the records we send; either may have a zero
+ * length, which means no CID in that direction.
+ */
+int SSL_get0_dtls_cid(const SSL *s, const unsigned char **own,
+    size_t *own_len, const unsigned char **peer, size_t *peer_len)
+{
+    const SSL_CONNECTION *sc = SSL_CONNECTION_FROM_CONST_SSL(s);
+    int negotiated = sc != NULL && sc->ext.dtls_cid.negotiated;
+
+    if (own != NULL)
+        *own = negotiated ? sc->ext.dtls_cid.sent : NULL;
+    if (own_len != NULL)
+        *own_len = negotiated ? sc->ext.dtls_cid.sent_len : 0;
+    if (peer != NULL)
+        *peer = negotiated ? sc->ext.dtls_cid.peer : NULL;
+    if (peer_len != NULL)
+        *peer_len = negotiated ? sc->ext.dtls_cid.peer_len : 0;
+    return negotiated;
+}
+
 /*
  * SSL_CTX_set_alpn_select_cb sets a callback function on |ctx| that is
  * called during ClientHello processing in order to select an ALPN protocol
@@ -7219,6 +7422,13 @@ void SSL_CTX_set_new_pending_conn_cb(SSL_CTX *c, SSL_new_pending_conn_cb_fn cb,
     c->new_pending_conn_arg = arg;
 }
 
+void SSL_CTX_set_dtls_peer_addr_change_cb(SSL_CTX *c,
+    SSL_dtls_peer_addr_change_cb_fn cb, void *arg)
+{
+    c->dtls_peer_addr_change_cb = cb;
+    c->dtls_peer_addr_change_arg = arg;
+}
+
 #ifndef OPENSSL_NO_DEPRECATED_4_0
 int SSL_client_hello_isv2(SSL *s)
 {
@@ -7734,12 +7944,26 @@ uint32_t SSL_get_recv_max_early_data(const SSL *s)
 
 __owur unsigned int ssl_get_max_send_fragment(const SSL_CONNECTION *sc)
 {
+    unsigned int frag;
+
     /* Return any active Max Fragment Len extension */
     if (sc->session != NULL && USE_MAX_FRAGMENT_LENGTH_EXT(sc->session))
-        return GET_MAX_FRAGMENT_LENGTH(sc->session);
+        frag = GET_MAX_FRAGMENT_LENGTH(sc->session);
+    else
+        frag = (unsigned int)sc->max_send_fragment;
 
-    /* return current SSL connection setting */
-    return (unsigned int)sc->max_send_fragment;
+    /*
+     * RFC 9146 section 5: the length of the DTLSInnerPlaintext, which is the
+     * content plus the one byte real_type (section 4, Figure 2), "MUST NOT
+     * exceed 2^14".  So a record sent with a CID carries one byte less than
+     * a DTLS 1.2 record without one.
+     */
+    if (SSL_CONNECTION_IS_DTLS(sc) && sc->version != DTLS1_3_VERSION
+        && sc->ext.dtls_cid.negotiated && sc->ext.dtls_cid.peer_len != 0
+        && frag > SSL3_RT_MAX_PLAIN_LENGTH - 1)
+        frag = SSL3_RT_MAX_PLAIN_LENGTH - 1;
+
+    return frag;
 }
 
 __owur unsigned int ssl_get_split_send_fragment(const SSL_CONNECTION *sc)
