$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/d1_lib.c.orig
+++ ssl/d1_lib.c
@@ -303,9 +303,11 @@ void dtls1_free(SSL *ssl)
      * The listener routes incoming packets to connections via this table,
      * so we must remove ourselves before freeing.
      */
-    if (s->d1 != NULL && s->d1->listener != NULL)
+    if (s->d1 != NULL && s->d1->listener != NULL) {
         ossl_dtls_listener_unregister_established_conn(s->d1->listener,
             &s->d1->peer_addr);
+        ossl_dtls_listener_unregister_conn_cid(s->d1->listener, ssl);
+    }
 #endif
 
     if (s->d1 != NULL)
@@ -1305,6 +1307,99 @@ static void dtls_listener_connection_free(SSL *ssl)
     SSL_free(ssl);
 }
 
+/*
+ * Free a connection of the listener, taking it out of the CID table first, as
+ * the callers take it out of the pending and established tables.  The caller
+ * holds dl->mutex.  dtls1_free() does not do it: the listener reference is
+ * cleared before SSL_free(), so that the connection does not reach back into
+ * the listener.
+ */
+static void dtls_listener_conn_free_locked(DTLS_LISTENER *dl, SSL *ssl)
+{
+    ossl_dgram_cid_lookup_unregister_ssl(dl->cid_conns, ssl);
+    dtls_listener_connection_free(ssl);
+}
+
+/*
+ * Give a new connection a CID of the listener's length and register it.  The
+ * CID is random: RFC 9146 section 8 notes that a CID "introduces the risk of
+ * linkability", and a counter would also tell the number of connections.
+ * The caller holds dl->mutex.
+ */
+#define DTLS_LISTENER_CID_TRIES 8
+static int dtls_listener_assign_cid(DTLS_LISTENER *dl, SSL *ssl)
+{
+    unsigned char cid[SSL_DTLS_CID_MAX_LEN];
+    int i;
+
+    for (i = 0; i < DTLS_LISTENER_CID_TRIES; i++) {
+        if (RAND_bytes_ex(dl->ssl.ctx->libctx, cid, dl->cid_len, 0) <= 0)
+            return 0;
+        if (ossl_dgram_cid_lookup_find(dl->cid_conns, cid, dl->cid_len) == NULL)
+            break;
+    }
+    /* A short CID length can run out of values; refuse the connection */
+    if (i == DTLS_LISTENER_CID_TRIES)
+        return 0;
+
+    if (!SSL_set1_dtls_cid(ssl, cid, dl->cid_len))
+        return 0;
+    if (!ossl_dgram_cid_lookup_register(dl->cid_conns, cid, dl->cid_len, ssl)) {
+        SSL_clear_dtls_cid(ssl);
+        return 0;
+    }
+    return 1;
+}
+
+/*
+ * Find the connection a tls12_cid record names (RFC 9146 section 3: "if the
+ * tls12_cid content type is set, then the CID is used to look up the
+ * connection").  The CID follows type, version, epoch and sequence_number
+ * (section 4, Figure 3).  Returns NULL for anything else.  The caller holds
+ * dl->mutex.
+ */
+#define DTLS_TLS12_CID_OFFSET 11
+/* RFC 9147 section 4, Figure 3: the CID follows the unified header's first byte */
+#define DTLS13_CID_OFFSET 1
+/*
+ * Is |first| the first byte of a DTLS 1.3 unified header with the C bit?
+ * RFC 9147 section 4, Figure 3: 0 0 1 C S L E E.
+ */
+static int dtls13_unified_with_cid(unsigned char first)
+{
+    return (first & DTLS13_UNI_HDR_FIX_BITS_MASK) == DTLS13_UNI_HDR_FIX_BITS
+        && (first & DTLS13_UNI_HDR_CID_BIT) != 0;
+}
+
+static SSL *dtls_listener_find_by_cid(DTLS_LISTENER *dl, const DGRAM_URXE *urxe)
+{
+    const unsigned char *data = ossl_dgram_urxe_data(urxe);
+    size_t off;
+
+    if (dl->cid_len == 0 || urxe->data_len == 0)
+        return NULL;
+    if (data[0] == SSL3_RT_TLS12_CID)
+        off = DTLS_TLS12_CID_OFFSET;
+    else if (dtls13_unified_with_cid(data[0]))
+        off = DTLS13_CID_OFFSET;
+    else
+        return NULL;
+    if (urxe->data_len < off + dl->cid_len)
+        return NULL;
+
+    return ossl_dgram_cid_lookup_find(dl->cid_conns, data + off, dl->cid_len);
+}
+
+/* Does the datagram begin with a record that carries a CID? */
+static int dtls_urxe_has_cid(const DGRAM_URXE *urxe)
+{
+    const unsigned char *data = ossl_dgram_urxe_data(urxe);
+
+    return urxe->data_len > 0
+        && (data[0] == SSL3_RT_TLS12_CID
+            || dtls13_unified_with_cid(data[0]));
+}
+
 /*
  * dtls_listener_create_conn_ssl - create an SSL object for a new connection.
  *
@@ -1331,6 +1426,9 @@ static SSL *dtls_listener_create_conn_ssl(DTLS_LISTENER *dl,
 
     SSL_set_accept_state(ssl);
 
+    if (dl->cid_len != 0 && !dtls_listener_assign_cid(dl, ssl))
+        goto err;
+
     /*
      * Create DTLS_RX for this connection. The demux is owned by the listener
      * and will outlive this connection. DTLS_RX manages the URXE queue for
@@ -1403,7 +1501,7 @@ static SSL *dtls_listener_create_conn_ssl(DTLS_LISTENER *dl,
     return ssl;
 
 err:
-    dtls_listener_connection_free(ssl);
+    dtls_listener_conn_free_locked(dl, ssl);
     return NULL;
 }
 
@@ -1445,8 +1543,22 @@ static void dtls_listener_packet_handler(DGRAM_URXE *urxe, void *arg)
 
     ossl_crypto_mutex_lock(dl->mutex);
 
+    /*
+     * A record with a CID (tls12_cid, or a DTLS 1.3 unified header with the
+     * C bit) goes to the connection its CID names, whatever address it came
+     * from: that is what the CID is for.  One naming no
+     * connection of ours is dropped; it cannot start a handshake.
+     */
+    if (dl->cid_len != 0 && dtls_urxe_has_cid(urxe)) {
+        conn_ssl = dtls_listener_find_by_cid(dl, urxe);
+        if (conn_ssl == NULL)
+            goto release;
+        /* The client's Finished is its first record with a CID */
+        pending = !SSL_is_init_finished(conn_ssl);
+    }
+
     /* Check established connections first */
-    if (dl->established_conns != NULL)
+    if (conn_ssl == NULL && dl->established_conns != NULL)
         conn_ssl = ossl_dgram_conn_lookup_find(dl->established_conns, urxe);
 
     /* Check pending connections */
@@ -1479,7 +1591,7 @@ static void dtls_listener_packet_handler(DGRAM_URXE *urxe, void *arg)
          * for this address.
          */
         if (!ossl_dgram_conn_lookup_register(dl->pending_conns, urxe, conn_ssl)) {
-            dtls_listener_connection_free(conn_ssl);
+            dtls_listener_conn_free_locked(dl, conn_ssl);
             goto release;
         }
 
@@ -1497,7 +1609,7 @@ static void dtls_listener_packet_handler(DGRAM_URXE *urxe, void *arg)
             sc = SSL_CONNECTION_FROM_SSL_ONLY(conn_ssl);
             if (sc == NULL || sc->d1 == NULL) {
                 ossl_dgram_conn_lookup_unregister(dl->pending_conns, &urxe->peer);
-                dtls_listener_connection_free(conn_ssl);
+                dtls_listener_conn_free_locked(dl, conn_ssl);
                 goto release;
             }
 
@@ -1522,7 +1634,7 @@ static void dtls_listener_packet_handler(DGRAM_URXE *urxe, void *arg)
                  * holds only its single reference and the free is safe.
                  */
                 ossl_dgram_conn_lookup_unregister(dl->pending_conns, &urxe->peer);
-                dtls_listener_connection_free(conn_ssl);
+                dtls_listener_conn_free_locked(dl, conn_ssl);
                 goto release;
             }
 
@@ -1900,6 +2012,12 @@ SSL *ossl_dtls_new_listener(SSL_CTX *ctx, uint64_t flags)
         goto err;
     }
 
+    dl->cid_conns = ossl_dgram_cid_lookup_new();
+    if (dl->cid_conns == NULL) {
+        ERR_raise(ERR_LIB_SSL, ERR_R_CRYPTO_LIB);
+        goto err;
+    }
+
     dl->net_rbio = NULL;
     dl->net_wbio = NULL;
     tsan_store(&dl->listening, 0);
@@ -2013,6 +2131,10 @@ void ossl_dtls_listener_free(SSL *s)
         dl->established_conns = NULL;
     }
 
+    /* The CID table does not own the connections either */
+    ossl_dgram_cid_lookup_free(dl->cid_conns);
+    dl->cid_conns = NULL;
+
     ossl_crypto_mutex_free(&dl->mutex);
 
     /* Free the demux after all connections that reference it are freed */
@@ -2413,7 +2535,7 @@ static int dtls_listener_drive_pass(DTLS_LISTENER *dl, int last_pass,
 
             /* Add to established connections (inline, we already hold mutex) */
             if (dl->established_conns == NULL || !ossl_dgram_conn_lookup_register_addr(dl->established_conns, &sc->d1->peer_addr, ssl)) {
-                dtls_listener_connection_free(ssl);
+                dtls_listener_conn_free_locked(dl, ssl);
                 continue;
             }
 
@@ -2424,7 +2546,7 @@ static int dtls_listener_drive_pass(DTLS_LISTENER *dl, int last_pass,
                 /* Failed to add to queue, unregister and free */
                 ossl_dgram_conn_lookup_unregister(dl->established_conns,
                     &sc->d1->peer_addr);
-                dtls_listener_connection_free(ssl);
+                dtls_listener_conn_free_locked(dl, ssl);
             }
         }
     }
@@ -2445,7 +2567,7 @@ static int dtls_listener_drive_pass(DTLS_LISTENER *dl, int last_pass,
         if (sc != NULL && sc->d1 != NULL)
             ossl_dgram_conn_lookup_unregister(dl->pending_conns, &sc->d1->peer_addr);
 
-        dtls_listener_connection_free(ssl);
+        dtls_listener_conn_free_locked(dl, ssl);
     }
 
     *again = dl->pending_input;
@@ -2661,6 +2783,7 @@ end:
              */
             if (sc != NULL && sc->d1 != NULL)
                 ossl_dtls_listener_unregister_established_conn(ssl, &sc->d1->peer_addr);
+            ossl_dtls_listener_unregister_conn_cid(ssl, conn);
             dtls_listener_connection_free(conn);
             ERR_raise(ERR_LIB_SSL, ERR_R_INTERNAL_ERROR);
             return NULL;
@@ -2888,6 +3011,347 @@ void ossl_dtls_listener_unregister_established_conn(SSL *s, const BIO_ADDR *peer
     ossl_crypto_mutex_unlock(dl->mutex);
 }
 
+/*
+ * ossl_dtls_listener_unregister_conn_cid - remove a connection's CID from the
+ * listener's CID table.  Called wherever a listener's connection is freed.
+ */
+void ossl_dtls_listener_unregister_conn_cid(SSL *s, SSL *conn)
+{
+    DTLS_LISTENER *dl;
+
+    if (s == NULL || !IS_DTLS_LISTENER(s))
+        return;
+
+    dl = (DTLS_LISTENER *)s;
+
+    ossl_crypto_mutex_lock(dl->mutex);
+    ossl_dgram_cid_lookup_unregister_ssl(dl->cid_conns, conn);
+    ossl_crypto_mutex_unlock(dl->mutex);
+}
+
+int ossl_dtls_listener_add_conn_cid(SSL *s, SSL *conn, const unsigned char *cid,
+    size_t cid_len)
+{
+    DTLS_LISTENER *dl;
+    int ok;
+
+    if (s == NULL || !IS_DTLS_LISTENER(s))
+        return 1;
+
+    dl = (DTLS_LISTENER *)s;
+
+    ossl_crypto_mutex_lock(dl->mutex);
+    ok = dl->cid_len == 0
+        || (cid_len == dl->cid_len
+            && ossl_dgram_cid_lookup_register(dl->cid_conns, cid, cid_len,
+                conn));
+    ossl_crypto_mutex_unlock(dl->mutex);
+    return ok;
+}
+
+/*
+ * The CID length a listener gives its connections, 0 if none or if |s| is
+ * not a DTLS listener.
+ */
+size_t ossl_dtls_listener_cid_len(SSL *s)
+{
+    DTLS_LISTENER *dl;
+    size_t len;
+
+    if (s == NULL || !IS_DTLS_LISTENER(s))
+        return 0;
+
+    dl = (DTLS_LISTENER *)s;
+
+    ossl_crypto_mutex_lock(dl->mutex);
+    len = dl->cid_len;
+    ossl_crypto_mutex_unlock(dl->mutex);
+    return len;
+}
+
+/*
+ * Move a listener's connection from |old_addr| to |new_addr| in the
+ * established table, so that records without a CID from the new address also
+ * find it.  Refused if another connection already has |new_addr|.
+ */
+static int dtls_listener_move_conn(SSL *s, SSL *conn, const BIO_ADDR *old_addr,
+    const BIO_ADDR *new_addr)
+{
+    DTLS_LISTENER *dl;
+    DGRAM_URXE key;
+    SSL *other;
+    int ok = 0;
+
+    if (s == NULL || !IS_DTLS_LISTENER(s))
+        return 0;
+
+    dl = (DTLS_LISTENER *)s;
+    memset(&key, 0, sizeof(key));
+    BIO_ADDR_copy(&key.peer, new_addr);
+
+    ossl_crypto_mutex_lock(dl->mutex);
+    other = ossl_dgram_conn_lookup_find(dl->established_conns, &key);
+    if (other == NULL) {
+        ossl_dgram_conn_lookup_unregister(dl->established_conns, old_addr);
+        ok = ossl_dgram_conn_lookup_register_addr(dl->established_conns,
+            new_addr, conn);
+        /* Keep the connection findable by its old address on failure */
+        if (!ok)
+            ossl_dgram_conn_lookup_register_addr(dl->established_conns,
+                old_addr, conn);
+    }
+    ossl_crypto_mutex_unlock(dl->mutex);
+    return ok;
+}
+
+static int dtls_addr_equal(const BIO_ADDR *a, const BIO_ADDR *b)
+{
+    unsigned char ra[sizeof(BIO_ADDR)], rb[sizeof(BIO_ADDR)];
+    size_t la = 0, lb = 0;
+
+    if (BIO_ADDR_family(a) != BIO_ADDR_family(b)
+        || BIO_ADDR_rawport(a) != BIO_ADDR_rawport(b)
+        || !BIO_ADDR_rawaddress(a, NULL, &la)
+        || !BIO_ADDR_rawaddress(b, NULL, &lb)
+        || la != lb || la > sizeof(ra)
+        || !BIO_ADDR_rawaddress(a, ra, NULL)
+        || !BIO_ADDR_rawaddress(b, rb, NULL))
+        return 0;
+    return memcmp(ra, rb, la) == 0;
+}
+
+/* RFC 9853 section 4, Figure 1 */
+#define DTLS_RRC_PATH_CHALLENGE 0
+#define DTLS_RRC_PATH_RESPONSE 1
+#define DTLS_RRC_PATH_DROP 2
+/* "Each message carries a Cookie, an 8-byte field" */
+#define DTLS_RRC_COOKIE_LEN 8
+/*
+ * RFC 9853 section 5.5: "If an implementation has no way to obtain
+ * information regarding the RTT of the active path, T SHOULD be set to 1
+ * second."
+ */
+#define DTLS_RRC_TIMEOUT_MS 1000
+
+static void dtls_move_peer(SSL_CONNECTION *s, const BIO_ADDR *new_addr);
+
+/*
+ * Send a return_routability_check message to |to|, or where the connection
+ * sends if |to| is NULL.  A listener's connections share the listener's BIO
+ * and pass each record's address to it, so a message for another address is
+ * sent with the record layer pointed there for the one write.  The message
+ * "MUST be authenticated and encrypted using the currently active security
+ * context" (section 4), which do_dtls1_write() does.
+ */
+static int dtls_rrc_send(SSL_CONNECTION *s, unsigned char msg_type,
+    const unsigned char *cookie, const BIO_ADDR *to)
+{
+    unsigned char msg[1 + DTLS_RRC_COOKIE_LEN];
+    size_t written;
+    int ret;
+
+    msg[0] = msg_type;
+    memcpy(msg + 1, cookie, DTLS_RRC_COOKIE_LEN);
+
+    if (to != NULL && s->rlayer.wrlmethod->set1_peer != NULL
+        && !s->rlayer.wrlmethod->set1_peer(s->rlayer.wrl, to))
+        return 0;
+    ret = do_dtls1_write(s, SSL3_RT_RETURN_ROUTABILITY_CHECK, msg,
+        sizeof(msg), &written);
+    if (to != NULL && s->rlayer.wrlmethod->set1_peer != NULL)
+        s->rlayer.wrlmethod->set1_peer(s->rlayer.wrl, &s->d1->peer_addr);
+    return ret > 0;
+}
+
+/*-
+ * RFC 9853 section 5.1, the basic check:
+ *   "1. The receiver (i.e., the initiator) creates a
+ *       return_routability_check message of type path_challenge and places
+ *       the unpredictable cookie into the message.
+ *    2. The message is sent to the observed new address and a timer T ...
+ *       is started."
+ * A check already running is left to finish or time out: "the presented
+ * algorithms are not designed to handle nested rebindings" (section 5).
+ * Until it succeeds the connection keeps sending to the address it had, so
+ * nothing larger than the challenge goes to the unvalidated one (section 5,
+ * "limit the data sent to the unvalidated address to the anti-amplification
+ * limit").  The enhanced check of section 5.2 is not implemented.
+ */
+static void dtls_rrc_start(SSL_CONNECTION *s, const BIO_ADDR *new_addr)
+{
+    SSL *ssl = SSL_CONNECTION_GET_SSL(s);
+    OSSL_TIME now = dtls_listener_get_time(ssl);
+
+    if (s->d1->rrc_pending && ossl_time_compare(now, s->d1->rrc_deadline) < 0)
+        return;
+
+    /*
+     * "RRC cookies must be _freshly_ generated using a reliable source of
+     * entropy" (section 8).
+     */
+    if (RAND_bytes_ex(ssl->ctx->libctx, s->d1->rrc_cookie,
+            sizeof(s->d1->rrc_cookie), 0)
+        <= 0) {
+        s->d1->rrc_pending = 0;
+        return;
+    }
+    s->d1->rrc_addr = *new_addr;
+    s->d1->rrc_deadline = ossl_time_add(now, ossl_ms2time(DTLS_RRC_TIMEOUT_MS));
+    s->d1->rrc_pending = dtls_rrc_send(s, DTLS_RRC_PATH_CHALLENGE,
+        s->d1->rrc_cookie, new_addr);
+}
+
+/*
+ * Handle a return_routability_check record that the record layer has passed
+ * up, and so decrypted and verified (RFC 9853 section 4).
+ */
+void ossl_dtls_rrc_record(SSL_CONNECTION *s, const unsigned char *data,
+    size_t len)
+{
+    SSL *ssl = SSL_CONNECTION_GET_SSL(s);
+
+    /*
+     * "implementations MUST be able to parse and gracefully ignore messages
+     * with an unknown msg_type"; the three known ones are one byte and a
+     * cookie, and anything else is invalid, which section 5.4 says to
+     * discard silently.
+     */
+    if (len != 1 + DTLS_RRC_COOKIE_LEN)
+        return;
+
+    switch (data[0]) {
+    case DTLS_RRC_PATH_CHALLENGE:
+        /*
+         * Section 5.4: "The responder MUST NOT delay sending an elicited
+         * path_response", "MUST send exactly one path_response or path_drop
+         * message for each valid path_challenge", and "MUST send the
+         * path_response or the path_drop to the address from which the
+         * corresponding path_challenge was received".  A connection with a
+         * BIO of its own sends where that BIO sends; a listener's goes
+         * back to the challenge's source.  path_drop is for a responder
+         * that has moved to another path of its own accord, which this one
+         * never does, so the answer is always path_response.
+         */
+        dtls_rrc_send(s, DTLS_RRC_PATH_RESPONSE, data + 1,
+            s->d1->listener != NULL && s->d1->rx_peer_set ? &s->d1->rx_peer
+                                                         : NULL);
+        break;
+    case DTLS_RRC_PATH_RESPONSE:
+        /*
+         * Section 5.1: "4. When the initiator receives the
+         * return_routability_check message of type path_response and
+         * verifies that it contains the sent cookie, it updates the peer
+         * address binding.  5. If T expires, the peer address binding is
+         * not updated."  Anything else "MUST silently discard" (5.4).
+         */
+        if (!s->d1->rrc_pending
+            || ossl_time_compare(dtls_listener_get_time(ssl),
+                   s->d1->rrc_deadline)
+                >= 0
+            || CRYPTO_memcmp(data + 1, s->d1->rrc_cookie,
+                   DTLS_RRC_COOKIE_LEN)
+                != 0)
+            return;
+        s->d1->rrc_pending = 0;
+        dtls_move_peer(s, &s->d1->rrc_addr);
+        break;
+    default:
+        /* path_drop answers the enhanced check, which is not sent */
+        break;
+    }
+}
+
+/*-
+ * Note a record that the record layer has passed up, and so verified, and
+ * move the connection to the address it came from if RFC 9146 section 6
+ * allows.  The receiver "MUST NOT replace the address it uses for sending
+ * records to its peer with the source address specified in the received
+ * datagram, unless the following three conditions are met":
+ *
+ *   * "The received datagram has been cryptographically verified": records
+ *     of epoch 0 are not protected and are never considered.
+ *   * "The received datagram is "newer" (in terms of both epoch and sequence
+ *     number) than the newest datagram received": |newest_epoch| and
+ *     |newest_seq| track that.
+ *   * "There is a strategy for ensuring that the new peer address is able
+ *     to receive and process DTLS records.  No strategy is mandated by this
+ *     specification": the application's dtls_peer_addr_change_cb is that
+ *     strategy, and without one the address never changes.
+ *
+ * Only a listener's connections are considered.  A connection with a BIO of
+ * its own sends where that BIO sends, which the library does not decide.
+ * The source is that of the datagram the record layer took last; a record
+ * the record layer had kept back from an earlier datagram (a later epoch's,
+ * during a handshake) may come from elsewhere, so only records of the epoch
+ * that was current when the datagram was taken are considered.
+ */
+void ossl_dtls_note_record(SSL_CONNECTION *s, uint64_t epoch, uint64_t seq)
+{
+    SSL *ssl = SSL_CONNECTION_GET_USER_SSL(s);
+    SSL_CTX *ctx = SSL_CONNECTION_GET_CTX(s);
+    int newer;
+
+    if (s->d1 == NULL)
+        return;
+
+    newer = !s->d1->have_newest || epoch > s->d1->newest_epoch
+        || (epoch == s->d1->newest_epoch && seq > s->d1->newest_seq);
+    if (!newer)
+        return;
+    s->d1->have_newest = 1;
+    s->d1->newest_epoch = epoch;
+    s->d1->newest_seq = seq;
+
+    /*
+     * Section 6 is about records with a CID, which are the ones we receive
+     * when our own CID is not empty.
+     */
+    if (s->d1->listener == NULL || !s->d1->rx_peer_set || epoch == 0
+        || epoch != s->d1->rx_epoch
+        || !s->ext.dtls_cid.negotiated || s->ext.dtls_cid.sent_len == 0
+        || BIO_ADDR_family(&s->d1->peer_addr) == AF_UNSPEC
+        || dtls_addr_equal(&s->d1->rx_peer, &s->d1->peer_addr))
+        return;
+
+    /*
+     * RFC 9853 section 3.1: "when both CID and RRC have been successfully
+     * negotiated for the session, if a record with CID is received that has
+     * the source address of the enclosing UDP datagram different from what
+     * is currently associated with that CID value, the receiver SHOULD
+     * perform a return routability check".  The address moves when the
+     * check succeeds, in ossl_dtls_rrc_record().
+     */
+    if (s->ext.dtls_cid.rrc_negotiated) {
+        dtls_rrc_start(s, &s->d1->rx_peer);
+        return;
+    }
+
+    /* Without RRC, the application's own mechanism (section 3.1) decides */
+    if (ctx->dtls_peer_addr_change_cb == NULL
+        || !ctx->dtls_peer_addr_change_cb(ssl, &s->d1->peer_addr,
+            &s->d1->rx_peer, ctx->dtls_peer_addr_change_arg))
+        return;
+
+    dtls_move_peer(s, &s->d1->rx_peer);
+}
+
+/*
+ * Make |new_addr| the address a listener's connection sends to, and the one
+ * the listener finds it by.
+ */
+static void dtls_move_peer(SSL_CONNECTION *s, const BIO_ADDR *new_addr)
+{
+    BIO_ADDR old_addr;
+
+    old_addr = s->d1->peer_addr;
+    if (!dtls_listener_move_conn(s->d1->listener, SSL_CONNECTION_GET_SSL(s),
+            &old_addr, new_addr))
+        return;
+    s->d1->peer_addr = *new_addr;
+    if (s->rlayer.wrlmethod != NULL && s->rlayer.wrlmethod->set1_peer != NULL)
+        s->rlayer.wrlmethod->set1_peer(s->rlayer.wrl, &s->d1->peer_addr);
+}
+
 /*
  * ossl_dtls_listener_clear_established_conns - clear and recreate the
  * established_conns table.
@@ -3012,6 +3476,9 @@ int ossl_dtls_get_value_uint(SSL *s, uint32_t class_, uint32_t id, uint64_t *val
     case SSL_VALUE_DTLS_LISTENER_MAX_DGRAM_SIZE:
         *value = (uint64_t)dl->max_dgram_size;
         break;
+    case SSL_VALUE_DTLS_LISTENER_CID_LEN:
+        *value = (uint64_t)dl->cid_len;
+        break;
     default:
         ERR_raise(ERR_LIB_SSL, SSL_R_UNSUPPORTED_CONFIG_VALUE);
         ret = 0;
@@ -3119,6 +3586,24 @@ int ossl_dtls_set_value_uint(SSL *s, uint32_t class_, uint32_t id, uint64_t valu
             dl->max_dgram_size = (size_t)value;
         }
         break;
+    case SSL_VALUE_DTLS_LISTENER_CID_LEN:
+        /* RFC 9146 section 3: opaque cid<0..2^8-1>; 0 turns CIDs off */
+        if (value > SSL_DTLS_CID_MAX_LEN) {
+            ERR_raise(ERR_LIB_SSL, ERR_R_PASSED_INVALID_ARGUMENT);
+            ret = 0;
+            break;
+        }
+        /*
+         * The length is how the listener finds the end of every CID it
+         * routes by, so it cannot change under connections that have one.
+         */
+        if (ossl_dgram_cid_lookup_num_items(dl->cid_conns) != 0) {
+            ERR_raise(ERR_LIB_SSL, ERR_R_SHOULD_NOT_HAVE_BEEN_CALLED);
+            ret = 0;
+            break;
+        }
+        dl->cid_len = (size_t)value;
+        break;
     default:
         ERR_raise(ERR_LIB_SSL, SSL_R_UNSUPPORTED_CONFIG_VALUE);
         ret = 0;
