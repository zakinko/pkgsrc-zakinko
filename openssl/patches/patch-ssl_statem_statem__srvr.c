$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/statem/statem_srvr.c.orig
+++ ssl/statem/statem_srvr.c
@@ -162,6 +162,8 @@ static int ossl_statem_server13_read_transition(SSL_CONNECTION *s, int mt)
 
     case TLS_ST_SW_KEY_UPDATE:
     case TLS_ST_SW_SESSION_TICKET:
+    case TLS_ST_SW_NEW_CONNECTION_ID:
+    case TLS_ST_SW_REQUEST_CONNECTION_ID:
         if (mt == DTLS13_MT_ACK) {
             st->pre_ack_hand_state = st->hand_state;
             st->hand_state = TLS_ST_SR_ACK;
@@ -196,6 +198,16 @@ static int ossl_statem_server13_read_transition(SSL_CONNECTION *s, int mt)
             return 1;
         }
 
+        /* RFC 9147 section 9, DTLS 1.3 post-handshake messages */
+        if (mt == SSL3_MT_NEW_CONNECTION_ID && SSL_CONNECTION_IS_DTLS13(s)) {
+            st->hand_state = TLS_ST_SR_NEW_CONNECTION_ID;
+            return 1;
+        }
+        if (mt == SSL3_MT_REQUEST_CONNECTION_ID && SSL_CONNECTION_IS_DTLS13(s)) {
+            st->hand_state = TLS_ST_SR_REQUEST_CONNECTION_ID;
+            return 1;
+        }
+
         if (mt == DTLS13_MT_ACK) {
             st->pre_ack_hand_state = st->hand_state;
             st->hand_state = TLS_ST_SR_ACK;
@@ -636,6 +648,14 @@ static WRITE_TRAN ossl_statem_server13_write_transition(SSL_CONNECTION *s)
             st->hand_state = TLS_ST_SW_KEY_UPDATE;
             return WRITE_TRAN_CONTINUE;
         }
+        if (s->ext.dtls_cid.ncid_pending) {
+            st->hand_state = TLS_ST_SW_NEW_CONNECTION_ID;
+            return WRITE_TRAN_CONTINUE;
+        }
+        if (s->ext.dtls_cid.rcid_num != 0) {
+            st->hand_state = TLS_ST_SW_REQUEST_CONNECTION_ID;
+            return WRITE_TRAN_CONTINUE;
+        }
         if (s->post_handshake_auth == SSL_PHA_REQUEST_PENDING) {
             st->hand_state = TLS_ST_SW_CERT_REQ;
             return WRITE_TRAN_CONTINUE;
@@ -779,6 +799,8 @@ static WRITE_TRAN ossl_statem_server13_write_transition(SSL_CONNECTION *s)
         return WRITE_TRAN_CONTINUE;
 
     case TLS_ST_SR_KEY_UPDATE:
+    case TLS_ST_SR_NEW_CONNECTION_ID:
+    case TLS_ST_SR_REQUEST_CONNECTION_ID:
         if (SSL_CONNECTION_IS_DTLS13(s)) {
             st->deferred_ack_state = TLS_ST_OK;
             st->hand_state = TLS_ST_SW_ACK;
@@ -786,6 +808,8 @@ static WRITE_TRAN ossl_statem_server13_write_transition(SSL_CONNECTION *s)
         }
         /* Fall through */
     case TLS_ST_SW_KEY_UPDATE:
+    case TLS_ST_SW_NEW_CONNECTION_ID:
+    case TLS_ST_SW_REQUEST_CONNECTION_ID:
         if (SSL_CONNECTION_IS_DTLS13(s))
             /* We wait for ACK */
             return WRITE_TRAN_FINISHED;
@@ -820,6 +844,13 @@ static WRITE_TRAN ossl_statem_server13_write_transition(SSL_CONNECTION *s)
             st->ack_for_retransmit = 0;
             return WRITE_TRAN_FINISHED;
         }
+        /*
+         * RFC 9147 section 9: "Endpoints SHOULD respond to
+         * RequestConnectionId by sending a NewConnectionId ... as soon as
+         * possible."  TLS_ST_OK would end the handshake first.
+         */
+        if (st->hand_state == TLS_ST_OK && s->ext.dtls_cid.ncid_pending)
+            st->hand_state = TLS_ST_SW_NEW_CONNECTION_ID;
 
         return WRITE_TRAN_CONTINUE;
     }
@@ -1330,6 +1361,13 @@ WORK_STATE ossl_statem_server_post_work(SSL_CONNECTION *s, WORK_STATE wst)
         }
         break;
 
+    case TLS_ST_SW_NEW_CONNECTION_ID:
+    case TLS_ST_SW_REQUEST_CONNECTION_ID:
+        /* Nothing follows them in this flight to push them out */
+        if (statem_flush(s) != 1)
+            return WORK_MORE_A;
+        break;
+
     case TLS_ST_SW_KEY_UPDATE:
         if (statem_flush(s) != 1)
             return WORK_MORE_A;
@@ -1474,6 +1512,16 @@ int ossl_statem_server_construct_message(SSL_CONNECTION *s,
         *mt = SSL3_MT_KEY_UPDATE;
         break;
 
+    case TLS_ST_SW_NEW_CONNECTION_ID:
+        *confunc = tls_construct_new_connection_id;
+        *mt = SSL3_MT_NEW_CONNECTION_ID;
+        break;
+
+    case TLS_ST_SW_REQUEST_CONNECTION_ID:
+        *confunc = tls_construct_request_connection_id;
+        *mt = SSL3_MT_REQUEST_CONNECTION_ID;
+        break;
+
     case TLS_ST_SW_ACK:
         *confunc = dtls_construct_ack;
         *mt = DTLS13_MT_ACK;
@@ -1546,6 +1594,12 @@ size_t ossl_statem_server_max_message_size(SSL_CONNECTION *s)
     case TLS_ST_SR_KEY_UPDATE:
         return KEY_UPDATE_MAX_LENGTH;
 
+    case TLS_ST_SR_NEW_CONNECTION_ID:
+        return NEW_CONNECTION_ID_MAX_LENGTH;
+
+    case TLS_ST_SR_REQUEST_CONNECTION_ID:
+        return REQUEST_CONNECTION_ID_MAX_LENGTH;
+
     case TLS_ST_SR_ACK:
         return ACK_MAX_LENGTH;
     }
@@ -1599,6 +1653,12 @@ MSG_PROCESS_RETURN ossl_statem_server_process_message(SSL_CONNECTION *s,
     case TLS_ST_SR_KEY_UPDATE:
         return tls_process_key_update(s, pkt);
 
+    case TLS_ST_SR_NEW_CONNECTION_ID:
+        return tls_process_new_connection_id(s, pkt);
+
+    case TLS_ST_SR_REQUEST_CONNECTION_ID:
+        return tls_process_request_connection_id(s, pkt);
+
     case TLS_ST_SR_ACK:
         return dtls_process_ack(s, pkt);
     }
