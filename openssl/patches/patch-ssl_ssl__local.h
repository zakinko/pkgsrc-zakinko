$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/ssl_local.h.orig
+++ ssl/ssl_local.h
@@ -771,6 +771,8 @@ typedef enum tlsext_index_en {
     TLSEXT_IDX_application_layer_protocol_negotiation,
     TLSEXT_IDX_use_srtp,
     TLSEXT_IDX_encrypt_then_mac,
+    TLSEXT_IDX_connection_id,
+    TLSEXT_IDX_rrc,
     TLSEXT_IDX_signed_certificate_timestamp,
     TLSEXT_IDX_extended_master_secret,
     TLSEXT_IDX_signature_algorithms_cert,
@@ -1089,6 +1091,10 @@ struct ssl_ctx_st {
     SSL_new_pending_conn_cb_fn new_pending_conn_cb;
     void *new_pending_conn_arg;
 
+    /* Callback deciding DTLS peer address changes, RFC 9146 section 6 */
+    SSL_dtls_peer_addr_change_cb_fn dtls_peer_addr_change_cb;
+    void *dtls_peer_addr_change_arg;
+
     /* TLS extensions. */
     struct {
         /* TLS extensions servername callback */
@@ -1342,6 +1348,15 @@ struct ssl_st {
     CRYPTO_EX_DATA ex_data;
 };
 
+/*
+ * DTLS 1.3 CID updates (RFC 9147 section 9): at most this many of our own
+ * further CIDs outstanding, and of the peer's spare CIDs kept.  "An endpoint
+ * MAY handle requests which it considers excessive by responding with a
+ * NewConnectionId message containing fewer than num_cids CIDs".
+ */
+#define DTLS_CID_MAX_SPARES 4
+#define DTLS_CID_MAX_OWN_MORE 8
+
 struct ssl_connection_st {
     /* type identifier and common data */
     struct ssl_st ssl;
@@ -1902,6 +1917,62 @@ struct ssl_connection_st {
         /* Set to one if we have negotiated ETM */
         bool use_etm;
 
+        /*
+         * DTLS 1.2 Connection ID (RFC 9146).  Each side names in the
+         * "connection_id" extension the CID it wants to receive (section 3),
+         * so |own| goes out in our extension and is expected in records we
+         * read, and |peer| comes from the peer's extension and is put in
+         * records we write.  A zero length means no CID in that direction.
+         * The extension is negotiated afresh on every handshake (section 3),
+         * so |received|, |negotiated| and |peer| are reset by
+         * init_connection_id().
+         * |sent| is the copy of |own| that went out in this handshake: the
+         * application may change |own| for the next handshake while |sent|
+         * is still the one the record layer expects.
+         */
+        struct {
+            bool enabled;
+            unsigned char *own;
+            size_t own_len;
+            bool received;
+            bool negotiated;
+            unsigned char *sent;
+            size_t sent_len;
+            unsigned char *peer;
+            size_t peer_len;
+            /*
+             * Return Routability Check (RFC 9853), which needs the CID:
+             * "A client offering the rrc extension MUST also offer the
+             * connection_id extension" (section 3).
+             */
+            bool rrc_disabled;
+            bool rrc_received;
+            bool rrc_negotiated;
+            /*
+             * DTLS 1.3 CID updates (RFC 9147 section 9).  |own_more| holds
+             * the further CIDs of our own we gave the peer, each |sent_len|
+             * bytes: the length is not on the wire, so every CID we receive
+             * has to have the one length (RFC 9146 section 3).  |spares| are
+             * the peer's spare CIDs, kept until used; "Implementations
+             * which receive more spare CIDs than they wish to maintain MAY
+             * simply discard any extra CIDs."  |ncid_pending| and
+             * |rcid_num| are messages waiting to be sent; |rcid_unfulfilled|
+             * is a RequestConnectionId sent and not yet answered.
+             */
+            unsigned char *own_more;
+            size_t own_more_num;
+            struct {
+                size_t len;
+                unsigned char cid[SSL_DTLS_CID_MAX_LEN];
+            } spares[DTLS_CID_MAX_SPARES];
+            size_t spares_num;
+            int ncid_pending;
+            int ncid_usage;
+            size_t ncid_num;
+            unsigned int rcid_num;
+            bool rcid_unfulfilled;
+        } dtls_cid;
+
         /* Is the session perhaps suitable for early data? */
         bool early_data_ok;
 
@@ -2212,6 +2283,14 @@ static ossl_inline int dtls_msg_needs_ack(int sentbyserver, unsigned char msgtyp
     switch (msgtype) {
     case SSL3_MT_NEWSESSION_TICKET:
     case SSL3_MT_KEY_UPDATE:
+    /*
+     * RFC 9147 section 5.8.4 lists NewConnectionId and
+     * RequestConnectionId among the post-handshake messages, and section
+     * 7: "For post-handshake messages, ACKs SHOULD be sent once for
+     * each received and processed handshake record".
+     */
+    case SSL3_MT_NEW_CONNECTION_ID:
+    case SSL3_MT_REQUEST_CONNECTION_ID:
         return 1;
 
     case SSL3_MT_CERTIFICATE:
@@ -2283,6 +2362,28 @@ typedef struct dtls1_state_st {
      * listener's network BIO.
      */
     BIO_ADDR peer_addr;
+
+    /*
+     * Source of the datagram the record layer took last, and the epoch and
+     * sequence number of the newest record read so far: what RFC 9146
+     * section 6 needs to tell whether a record from a new address may move
+     * |peer_addr| to it.
+     */
+    BIO_ADDR rx_peer;
+    int rx_peer_set;
+    uint64_t rx_epoch;
+    int have_newest;
+    uint64_t newest_epoch;
+    uint64_t newest_seq;
+
+    /*
+     * A Return Routability Check (RFC 9853 section 5.1) in progress: the
+     * cookie sent in a path_challenge to |rrc_addr|, and when to give up.
+     */
+    int rrc_pending;
+    unsigned char rrc_cookie[8];
+    BIO_ADDR rrc_addr;
+    OSSL_TIME rrc_deadline;
 #endif
 
 #ifndef OPENSSL_NO_DTLS
@@ -2400,6 +2501,18 @@ typedef struct dtls_listener_st {
      */
     DGRAM_CONN_LOOKUP *established_conns;
 
+    /*
+     * DTLS 1.2 Connection IDs (RFC 9146).  When |cid_len| is not zero the
+     * listener gives every connection it makes a random CID of that length,
+     * and routes tls12_cid records by it in |cid_conns|.  A fixed length lets
+     * the listener find the end of a CID it did not negotiate itself:
+     * "implementations that want to use variable-length CIDs are responsible
+     * for constructing the CID in such a way that its length can be
+     * determined on reception" (section 3).  Protected by mutex.
+     */
+    size_t cid_len;
+    DGRAM_CID_LOOKUP *cid_conns;
+
     /* Have we started listening yet? */
     TSAN_QUALIFIER int listening;
 
@@ -3140,6 +3253,58 @@ BIO *ossl_dtls_listener_get_net_wbio(const SSL *s);
 /* Established connections API - these handle their own locking */
 SSL *ossl_dtls_listener_find_established_conn(DTLS_LISTENER *dl,
     const DGRAM_URXE *urxe);
+/**
+ * @brief Remove a connection's CID from its listener's CID table.
+ * @param s the listener, may be NULL
+ * @param conn the connection
+ */
+void ossl_dtls_listener_unregister_conn_cid(SSL *s, SSL *conn);
+
+/**
+ * @brief Get the CID length a DTLS listener gives its connections.
+ * @param s the listener, may be NULL
+ * @returns the length, 0 if none or if @p s is not a DTLS listener
+ */
+size_t ossl_dtls_listener_cid_len(SSL *s);
+
+/**
+ * @brief Note a verified DTLS record and apply RFC 9146 section 6 to a
+ * change of peer address.
+ * @param s the connection
+ * @param epoch the record's epoch
+ * @param seq the record's sequence number
+ */
+void ossl_dtls_note_record(SSL_CONNECTION *s, uint64_t epoch, uint64_t seq);
+
+/**
+ * @brief Is @p st a state that writes a NewConnectionId or
+ * RequestConnectionId message (RFC 9147 section 9)?
+ * @param st the handshake state
+ * @returns 1 if it is, 0 otherwise
+ */
+int ossl_statem_is_cid_update_write(OSSL_HANDSHAKE_STATE st);
+
+/**
+ * @brief Register a further CID of a listener's connection, so that the
+ * listener routes records carrying it to the connection.
+ * @param s the listener, may be NULL
+ * @param conn the connection
+ * @param cid the CID
+ * @param cid_len its length, which must be the listener's
+ * @returns 1 on success, 0 if the CID is taken or on error
+ */
+int ossl_dtls_listener_add_conn_cid(SSL *s, SSL *conn, const unsigned char *cid,
+    size_t cid_len);
+
+/**
+ * @brief Process a return_routability_check record (RFC 9853 section 4).
+ * @param s the connection
+ * @param data the record's content
+ * @param len the length of @p data
+ */
+void ossl_dtls_rrc_record(SSL_CONNECTION *s, const unsigned char *data,
+    size_t len);
+
 void ossl_dtls_listener_unregister_established_conn(SSL *s,
     const BIO_ADDR *peer_addr);
 void ossl_dtls_listener_clear_established_conns(DTLS_LISTENER *dl);
