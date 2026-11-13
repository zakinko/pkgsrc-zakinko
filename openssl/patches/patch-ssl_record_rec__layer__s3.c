$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/record/rec_layer_s3.c.orig
+++ ssl/record/rec_layer_s3.c
@@ -1192,6 +1192,16 @@ static int rlayer_dtls_get_urxe_packet(void *cbarg, unsigned char **data,
     if (urxe == NULL)
         return 0;
 
+    /*
+     * Remember where this datagram came from, and the epoch read at the
+     * time, for ossl_dtls_note_record().
+     */
+    s->d1->rx_peer = urxe->peer;
+    s->d1->rx_peer_set = 1;
+    if (s->rlayer.rrlmethod == NULL || s->rlayer.rrlmethod->get_epoch == NULL
+        || !s->rlayer.rrlmethod->get_epoch(s->rlayer.rrl, &s->d1->rx_epoch))
+        s->d1->rx_peer_set = 0;
+
     *data = ossl_dgram_urxe_data(urxe);
     *len = urxe->data_len;
     *packet_handle = urxe;
@@ -1313,8 +1323,8 @@ int ssl_set_new_record_layer(SSL_CONNECTION *s, int version,
     int mactype, const EVP_MD *md,
     const SSL_COMP *comp, const EVP_MD *kdfdigest)
 {
-    OSSL_PARAM options[5], *opts = options;
-    OSSL_PARAM settings[6], *set = settings;
+    OSSL_PARAM options[6], *opts = options;
+    OSSL_PARAM settings[7], *set = settings;
     const OSSL_RECORD_METHOD **thismethod;
     OSSL_RECORD_LAYER **thisrl, *newrl = NULL;
     BIO *thisbio;
@@ -1386,6 +1396,14 @@ int ssl_set_new_record_layer(SSL_CONNECTION *s, int version,
             &s->rlayer.default_read_buf_len);
         *opts++ = OSSL_PARAM_construct_int(OSSL_LIBSSL_RECORD_LAYER_PARAM_READ_AHEAD,
             &s->rlayer.read_ahead);
+        /* Our further CIDs (RFC 9147 section 9), for the CID set below */
+        if (SSL_CONNECTION_IS_DTLS(s) && version == DTLS1_3_VERSION
+            && s->ext.dtls_cid.negotiated && s->ext.dtls_cid.own_more_num != 0
+            && (level == OSSL_RECORD_PROTECTION_LEVEL_HANDSHAKE
+                || level == OSSL_RECORD_PROTECTION_LEVEL_APPLICATION))
+            *opts++ = OSSL_PARAM_construct_octet_string(OSSL_LIBSSL_RECORD_LAYER_PARAM_DTLS_CID_MORE,
+                s->ext.dtls_cid.own_more,
+                s->ext.dtls_cid.own_more_num * s->ext.dtls_cid.sent_len);
     } else {
         *opts++ = OSSL_PARAM_construct_size_t(OSSL_LIBSSL_RECORD_LAYER_PARAM_BLOCK_PADDING,
             &s->rlayer.block_padding);
@@ -1455,6 +1473,37 @@ int ssl_set_new_record_layer(SSL_CONNECTION *s, int version,
                 &max_early_data);
     }
 
+    /*
+     * RFC 9146 section 3: with a non-zero length CID negotiated for a
+     * direction, records in that direction use the tls12_cid format "once
+     * encryption is enabled"; "Plaintext payloads never use the new record
+     * format".  The CID read is the one we sent in our extension, the CID
+     * written the one from the peer's.  In DTLS 1.3 the CID is negotiated
+     * in the hellos and carried from the handshake epoch on (RFC 9147
+     * section 9.1, Figure 15); early data goes before the server's CID is
+     * known and has none.
+     */
+    if (SSL_CONNECTION_IS_DTLS(s)
+        && (version == DTLS1_3_VERSION
+                ? level == OSSL_RECORD_PROTECTION_LEVEL_HANDSHAKE
+                    || level == OSSL_RECORD_PROTECTION_LEVEL_APPLICATION
+                : level == OSSL_RECORD_PROTECTION_LEVEL_APPLICATION)
+        && s->ext.dtls_cid.negotiated) {
+        unsigned char *cid;
+        size_t cid_len;
+
+        if (direction == OSSL_RECORD_DIRECTION_READ) {
+            cid = s->ext.dtls_cid.sent;
+            cid_len = s->ext.dtls_cid.sent_len;
+        } else {
+            cid = s->ext.dtls_cid.peer;
+            cid_len = s->ext.dtls_cid.peer_len;
+        }
+        if (cid_len != 0)
+            *set++ = OSSL_PARAM_construct_octet_string(OSSL_LIBSSL_RECORD_LAYER_PARAM_DTLS_CID,
+                cid, cid_len);
+    }
+
     *set = OSSL_PARAM_construct_end();
 
     /*
