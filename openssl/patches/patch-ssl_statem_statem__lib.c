$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/statem/statem_lib.c.orig
+++ ssl/statem/statem_lib.c
@@ -20,6 +20,7 @@
 #include <openssl/objects.h>
 #include <openssl/evp.h>
 #include <openssl/rsa.h>
+#include <openssl/rand.h>
 #include <openssl/x509.h>
 #include <openssl/trace.h>
 #include <openssl/encoder.h>
@@ -106,7 +107,8 @@ int ssl3_do_write(SSL_CONNECTION *s, uint8_t type)
         if (!SSL_CONNECTION_IS_TLS13(s)
             || (s->statem.hand_state != TLS_ST_SW_SESSION_TICKET
                 && s->statem.hand_state != TLS_ST_CW_KEY_UPDATE
-                && s->statem.hand_state != TLS_ST_SW_KEY_UPDATE))
+                && s->statem.hand_state != TLS_ST_SW_KEY_UPDATE
+                && !ossl_statem_is_cid_update_write(s->statem.hand_state)))
             if (!ssl3_finish_mac(s,
                     (unsigned char *)&s->init_buf->data[s->init_off],
                     written))
@@ -740,6 +742,250 @@ MSG_PROCESS_RETURN tls_process_key_update(SSL_CONNECTION *s, PACKET *pkt)
     return MSG_PROCESS_FINISHED_READING;
 }
 
+int ossl_statem_is_cid_update_write(OSSL_HANDSHAKE_STATE st)
+{
+    return st == TLS_ST_CW_NEW_CONNECTION_ID || st == TLS_ST_SW_NEW_CONNECTION_ID
+        || st == TLS_ST_CW_REQUEST_CONNECTION_ID
+        || st == TLS_ST_SW_REQUEST_CONNECTION_ID;
+}
+
+/* Pass a DTLS_CID or DTLS_CID_MORE value to a record layer's options */
+static int dtls_cid_set_rl(SSL_CONNECTION *s, int read, const char *key,
+    unsigned char *val, size_t len)
+{
+    OSSL_PARAM params[2];
+    const OSSL_RECORD_METHOD *meth = read ? s->rlayer.rrlmethod
+                                          : s->rlayer.wrlmethod;
+    OSSL_RECORD_LAYER *rl = read ? s->rlayer.rrl : s->rlayer.wrl;
+
+    params[0] = OSSL_PARAM_construct_octet_string(key, val, len);
+    params[1] = OSSL_PARAM_construct_end();
+    return meth != NULL && rl != NULL && meth->set_options != NULL
+        && meth->set_options(rl, params);
+}
+
+/*
+ * Make one more CID of our own, of the length of the one in our extension:
+ * the length is not on the wire, so all the CIDs we receive must share it
+ * (RFC 9146 section 3).  A connection of a listener routing by CID has it
+ * registered there too.
+ */
+static int dtls_cid_make_own(SSL_CONNECTION *s, unsigned char *cid)
+{
+    SSL *ssl = SSL_CONNECTION_GET_SSL(s);
+    size_t len = s->ext.dtls_cid.sent_len, i;
+    int tries;
+
+    for (tries = 0; tries < 8; tries++) {
+        int clash = 0;
+
+        if (RAND_bytes_ex(ssl->ctx->libctx, cid, len, 0) <= 0)
+            return 0;
+        clash = memcmp(cid, s->ext.dtls_cid.sent, len) == 0;
+        for (i = 0; !clash && i < s->ext.dtls_cid.own_more_num; i++)
+            clash = memcmp(cid, s->ext.dtls_cid.own_more + i * len, len) == 0;
+        if (clash)
+            continue;
+#ifndef OPENSSL_NO_SOCK
+        if (s->d1 != NULL && s->d1->listener != NULL
+            && !ossl_dtls_listener_add_conn_cid(s->d1->listener, ssl, cid, len))
+            continue;
+#endif
+        return 1;
+    }
+    return 0;
+}
+
+/*-
+ * RFC 9147 section 9:
+ *     struct {
+ *         ConnectionId cids<0..2^16-1>;
+ *         ConnectionIdUsage usage;
+ *     } NewConnectionId;
+ * The new CIDs are kept as well as the ones before: with "cid_spare",
+ * "either an existing or new CID MAY be used".  At most
+ * DTLS_CID_MAX_OWN_MORE are given out over the connection; past that the
+ * message carries fewer, as an answer to RequestConnectionId may ("An
+ * endpoint MAY handle requests which it considers excessive by responding
+ * with a NewConnectionId message containing fewer than num_cids CIDs,
+ * including no CIDs at all").
+ */
+CON_FUNC_RETURN tls_construct_new_connection_id(SSL_CONNECTION *s,
+    WPACKET *pkt)
+{
+    size_t len = s->ext.dtls_cid.sent_len, room, n, i;
+    unsigned char *more;
+
+    room = DTLS_CID_MAX_OWN_MORE - s->ext.dtls_cid.own_more_num;
+    n = s->ext.dtls_cid.ncid_num < room ? s->ext.dtls_cid.ncid_num : room;
+    more = OPENSSL_realloc(s->ext.dtls_cid.own_more,
+        (s->ext.dtls_cid.own_more_num + n) * len + 1);
+    if (more == NULL) {
+        SSLfatal(s, SSL_AD_INTERNAL_ERROR, ERR_R_CRYPTO_LIB);
+        return CON_FUNC_ERROR;
+    }
+    s->ext.dtls_cid.own_more = more;
+
+    if (!WPACKET_start_sub_packet_u16(pkt)) {
+        SSLfatal(s, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+        return CON_FUNC_ERROR;
+    }
+    for (i = 0; i < n; i++) {
+        unsigned char *cid = more + s->ext.dtls_cid.own_more_num * len;
+
+        if (!dtls_cid_make_own(s, cid)
+            || !WPACKET_sub_memcpy_u8(pkt, cid, len)) {
+            SSLfatal(s, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+            return CON_FUNC_ERROR;
+        }
+        s->ext.dtls_cid.own_more_num++;
+    }
+    if (!WPACKET_close(pkt)
+        || !WPACKET_put_bytes_u8(pkt, s->ext.dtls_cid.ncid_usage)
+        /* The read record layer has to take them before the peer uses them */
+        || (s->ext.dtls_cid.own_more_num != 0
+            && !dtls_cid_set_rl(s, 1, OSSL_LIBSSL_RECORD_LAYER_PARAM_DTLS_CID_MORE,
+                s->ext.dtls_cid.own_more, s->ext.dtls_cid.own_more_num * len))) {
+        SSLfatal(s, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+        return CON_FUNC_ERROR;
+    }
+
+    s->ext.dtls_cid.ncid_pending = 0;
+    return CON_FUNC_SUCCESS;
+}
+
+/* RFC 9147 section 9: struct { uint8 num_cids; } RequestConnectionId; */
+CON_FUNC_RETURN tls_construct_request_connection_id(SSL_CONNECTION *s,
+    WPACKET *pkt)
+{
+    if (!WPACKET_put_bytes_u8(pkt, s->ext.dtls_cid.rcid_num)) {
+        SSLfatal(s, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+        return CON_FUNC_ERROR;
+    }
+    s->ext.dtls_cid.rcid_num = 0;
+    s->ext.dtls_cid.rcid_unfulfilled = 1;
+    return CON_FUNC_SUCCESS;
+}
+
+/*
+ * RFC 9147 section 9: "Implementations which either did not negotiate the
+ * "connection_id" extension or which have negotiated receiving an empty CID
+ * MUST NOT send NewConnectionId" and "Implementations which detect a
+ * violation of these rules MUST terminate the connection with an
+ * "unexpected_message" alert."  The peer receives with the CID we send.
+ */
+MSG_PROCESS_RETURN tls_process_new_connection_id(SSL_CONNECTION *s,
+    PACKET *pkt)
+{
+    PACKET cids, cid;
+    unsigned int usage;
+    size_t first = 1;
+
+    if (!s->ext.dtls_cid.negotiated || s->ext.dtls_cid.peer_len == 0) {
+        SSLfatal(s, SSL_AD_UNEXPECTED_MESSAGE, SSL_R_UNEXPECTED_MESSAGE);
+        return MSG_PROCESS_ERROR;
+    }
+    if (!PACKET_get_length_prefixed_2(pkt, &cids)
+        || !PACKET_get_1(pkt, &usage)
+        || PACKET_remaining(pkt) != 0) {
+        SSLfatal(s, SSL_AD_DECODE_ERROR, SSL_R_LENGTH_MISMATCH);
+        return MSG_PROCESS_ERROR;
+    }
+    /*
+     * "If usage is set to "cid_immediate", then one of the new CIDs MUST be
+     * used immediately for all future records", which an empty list cannot
+     * give.
+     */
+    if ((usage != SSL_DTLS_CID_IMMEDIATE && usage != SSL_DTLS_CID_SPARE)
+        || (usage == SSL_DTLS_CID_IMMEDIATE && PACKET_remaining(&cids) == 0)) {
+        SSLfatal(s, SSL_AD_ILLEGAL_PARAMETER, SSL_R_BAD_EXTENSION);
+        return MSG_PROCESS_ERROR;
+    }
+
+    while (PACKET_remaining(&cids) != 0) {
+        if (!PACKET_get_length_prefixed_1(&cids, &cid)) {
+            SSLfatal(s, SSL_AD_DECODE_ERROR, SSL_R_LENGTH_MISMATCH);
+            return MSG_PROCESS_ERROR;
+        }
+        /*
+         * An empty CID would take the CID out of the records, which a
+         * negotiated CID does not allow (RFC 9147 section 4, "If a
+         * Connection ID is negotiated, then it MUST be contained in all
+         * datagrams").
+         */
+        if (PACKET_remaining(&cid) == 0) {
+            SSLfatal(s, SSL_AD_ILLEGAL_PARAMETER, SSL_R_BAD_EXTENSION);
+            return MSG_PROCESS_ERROR;
+        }
+        if (first && usage == SSL_DTLS_CID_IMMEDIATE) {
+            /* PACKET_memdup() frees what it is given first */
+            unsigned char *peer = NULL;
+            size_t peer_len;
+
+            /*
+             * "one of the new CIDs MUST be used immediately for all future
+             * records"; "Endpoints SHOULD use receiver-provided CIDs in the
+             * order they were provided", so the first.
+             */
+            if (!PACKET_memdup(&cid, &peer, &peer_len)
+                || !dtls_cid_set_rl(s, 0, OSSL_LIBSSL_RECORD_LAYER_PARAM_DTLS_CID,
+                    peer, peer_len)) {
+                OPENSSL_free(peer);
+                SSLfatal(s, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+                return MSG_PROCESS_ERROR;
+            }
+            OPENSSL_free(s->ext.dtls_cid.peer);
+            s->ext.dtls_cid.peer = peer;
+            s->ext.dtls_cid.peer_len = peer_len;
+        } else if (s->ext.dtls_cid.spares_num < DTLS_CID_MAX_SPARES) {
+            /* "MAY simply discard any extra CIDs" past those kept */
+            size_t i = s->ext.dtls_cid.spares_num++;
+
+            s->ext.dtls_cid.spares[i].len = PACKET_remaining(&cid);
+            memcpy(s->ext.dtls_cid.spares[i].cid, PACKET_data(&cid),
+                PACKET_remaining(&cid));
+        }
+        first = 0;
+    }
+    /*
+     * The answer to a RequestConnectionId is a NewConnectionId with
+     * "cid_spare" (section 9), which may hold fewer CIDs or none.
+     */
+    if (usage == SSL_DTLS_CID_SPARE)
+        s->ext.dtls_cid.rcid_unfulfilled = 0;
+
+    return MSG_PROCESS_FINISHED_READING;
+}
+
+/*
+ * RFC 9147 section 9: "Implementations MUST NOT send RequestConnectionId
+ * when sending an empty Connection ID", nor "if they did not negotiate a
+ * CID"; a violation "MUST terminate the connection with an
+ * "unexpected_message" alert".  The peer sends with the CID we sent.
+ * "Endpoints SHOULD respond to RequestConnectionId by sending a
+ * NewConnectionId with usage "cid_spare" containing num_cids CIDs as soon as
+ * possible."
+ */
+MSG_PROCESS_RETURN tls_process_request_connection_id(SSL_CONNECTION *s,
+    PACKET *pkt)
+{
+    unsigned int num;
+
+    if (!s->ext.dtls_cid.negotiated || s->ext.dtls_cid.sent_len == 0) {
+        SSLfatal(s, SSL_AD_UNEXPECTED_MESSAGE, SSL_R_UNEXPECTED_MESSAGE);
+        return MSG_PROCESS_ERROR;
+    }
+    if (!PACKET_get_1(pkt, &num) || PACKET_remaining(pkt) != 0) {
+        SSLfatal(s, SSL_AD_DECODE_ERROR, SSL_R_LENGTH_MISMATCH);
+        return MSG_PROCESS_ERROR;
+    }
+
+    s->ext.dtls_cid.ncid_pending = 1;
+    s->ext.dtls_cid.ncid_usage = SSL_DTLS_CID_SPARE;
+    s->ext.dtls_cid.ncid_num = num;
+    return MSG_PROCESS_FINISHED_READING;
+}
+
 /*
  * ssl3_take_mac calculates the Finished MAC for the handshakes messages seen
  * to far.
@@ -1710,7 +1956,9 @@ int tls_common_finish_mac(SSL_CONNECTION *s)
     /* KeyUpdate and NewSessionTicket do not need to be added */
     if (!SSL_CONNECTION_IS_VERSION13(s)
         || (s->s3.tmp.message_type != SSL3_MT_NEWSESSION_TICKET
-            && s->s3.tmp.message_type != SSL3_MT_KEY_UPDATE)) {
+            && s->s3.tmp.message_type != SSL3_MT_KEY_UPDATE
+            && s->s3.tmp.message_type != SSL3_MT_NEW_CONNECTION_ID
+            && s->s3.tmp.message_type != SSL3_MT_REQUEST_CONNECTION_ID)) {
         if (s->s3.tmp.message_type != SSL3_MT_SERVER_HELLO
             || s->init_num < srvhellorandom_offs + SSL3_RANDOM_SIZE
             || memcmp(hrrrandom,
