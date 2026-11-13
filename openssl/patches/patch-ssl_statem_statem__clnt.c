$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/statem/statem_clnt.c.orig
+++ ssl/statem/statem_clnt.c
@@ -184,6 +184,8 @@ static int ossl_statem_client13_read_transition(SSL_CONNECTION *s, int mt)
         break;
 
     case TLS_ST_CW_KEY_UPDATE:
+    case TLS_ST_CW_NEW_CONNECTION_ID:
+    case TLS_ST_CW_REQUEST_CONNECTION_ID:
     case TLS_ST_CW_FINISHED:
     case TLS_ST_OK:
         if (mt == DTLS13_MT_ACK) {
@@ -199,6 +201,15 @@ static int ossl_statem_client13_read_transition(SSL_CONNECTION *s, int mt)
             st->hand_state = TLS_ST_CR_KEY_UPDATE;
             return 1;
         }
+        /* RFC 9147 section 9, DTLS 1.3 post-handshake messages */
+        if (mt == SSL3_MT_NEW_CONNECTION_ID && SSL_CONNECTION_IS_DTLS13(s)) {
+            st->hand_state = TLS_ST_CR_NEW_CONNECTION_ID;
+            return 1;
+        }
+        if (mt == SSL3_MT_REQUEST_CONNECTION_ID && SSL_CONNECTION_IS_DTLS13(s)) {
+            st->hand_state = TLS_ST_CR_REQUEST_CONNECTION_ID;
+            return 1;
+        }
         if (mt == SSL3_MT_CERTIFICATE_REQUEST) {
             if (s->post_handshake_auth == SSL_PHA_EXT_SENT) {
                 s->post_handshake_auth = SSL_PHA_REQUESTED;
@@ -519,12 +530,16 @@ static WRITE_TRAN ossl_statem_client13_write_transition(SSL_CONNECTION *s)
 
     case TLS_ST_CR_KEY_UPDATE:
     case TLS_ST_CR_SESSION_TICKET:
+    case TLS_ST_CR_NEW_CONNECTION_ID:
+    case TLS_ST_CR_REQUEST_CONNECTION_ID:
         if (SSL_CONNECTION_IS_DTLS13(s)) {
             st->hand_state = TLS_ST_CW_ACK;
             return WRITE_TRAN_CONTINUE;
         }
         /* Fall-through */
     case TLS_ST_CW_KEY_UPDATE:
+    case TLS_ST_CW_NEW_CONNECTION_ID:
+    case TLS_ST_CW_REQUEST_CONNECTION_ID:
     case TLS_ST_CW_FINISHED:
         if (SSL_CONNECTION_IS_DTLS13(s))
             /* We wait for ACK */
@@ -548,6 +563,15 @@ static WRITE_TRAN ossl_statem_client13_write_transition(SSL_CONNECTION *s)
             st->ack_for_retransmit = 0;
             return WRITE_TRAN_FINISHED;
         }
+        /*
+         * RFC 9147 section 9: "Endpoints SHOULD respond to
+         * RequestConnectionId by sending a NewConnectionId ... as soon as
+         * possible."  TLS_ST_OK would end the handshake first.
+         */
+        if (s->ext.dtls_cid.ncid_pending) {
+            st->hand_state = TLS_ST_CW_NEW_CONNECTION_ID;
+            return WRITE_TRAN_CONTINUE;
+        }
         st->hand_state = TLS_ST_OK;
         return WRITE_TRAN_CONTINUE;
 
@@ -556,6 +580,14 @@ static WRITE_TRAN ossl_statem_client13_write_transition(SSL_CONNECTION *s)
             st->hand_state = TLS_ST_CW_KEY_UPDATE;
             return WRITE_TRAN_CONTINUE;
         }
+        if (s->ext.dtls_cid.ncid_pending) {
+            st->hand_state = TLS_ST_CW_NEW_CONNECTION_ID;
+            return WRITE_TRAN_CONTINUE;
+        }
+        if (s->ext.dtls_cid.rcid_num != 0) {
+            st->hand_state = TLS_ST_CW_REQUEST_CONNECTION_ID;
+            return WRITE_TRAN_CONTINUE;
+        }
 
         /* Try to read from the server instead */
         return WRITE_TRAN_FINISHED;
@@ -988,6 +1020,13 @@ WORK_STATE ossl_statem_client_post_work(SSL_CONNECTION *s, WORK_STATE wst)
         }
         break;
 
+    case TLS_ST_CW_NEW_CONNECTION_ID:
+    case TLS_ST_CW_REQUEST_CONNECTION_ID:
+        /* Nothing follows them in this flight to push them out */
+        if (statem_flush(s) != 1)
+            return WORK_MORE_A;
+        break;
+
     case TLS_ST_CW_KEY_UPDATE:
         if (statem_flush(s) != 1)
             return WORK_MORE_A;
@@ -1086,6 +1125,16 @@ int ossl_statem_client_construct_message(SSL_CONNECTION *s,
         *mt = SSL3_MT_KEY_UPDATE;
         break;
 
+    case TLS_ST_CW_NEW_CONNECTION_ID:
+        *confunc = tls_construct_new_connection_id;
+        *mt = SSL3_MT_NEW_CONNECTION_ID;
+        break;
+
+    case TLS_ST_CW_REQUEST_CONNECTION_ID:
+        *confunc = tls_construct_request_connection_id;
+        *mt = SSL3_MT_REQUEST_CONNECTION_ID;
+        break;
+
     case TLS_ST_CW_ACK:
         *confunc = dtls_construct_ack;
         *mt = DTLS13_MT_ACK;
@@ -1156,6 +1205,12 @@ size_t ossl_statem_client_max_message_size(SSL_CONNECTION *s)
     case TLS_ST_CR_KEY_UPDATE:
         return KEY_UPDATE_MAX_LENGTH;
 
+    case TLS_ST_CR_NEW_CONNECTION_ID:
+        return NEW_CONNECTION_ID_MAX_LENGTH;
+
+    case TLS_ST_CR_REQUEST_CONNECTION_ID:
+        return REQUEST_CONNECTION_ID_MAX_LENGTH;
+
     case TLS_ST_CR_ACK:
         return ACK_MAX_LENGTH;
     }
@@ -1222,6 +1277,12 @@ MSG_PROCESS_RETURN ossl_statem_client_process_message(SSL_CONNECTION *s,
     case TLS_ST_CR_KEY_UPDATE:
         return tls_process_key_update(s, pkt);
 
+    case TLS_ST_CR_NEW_CONNECTION_ID:
+        return tls_process_new_connection_id(s, pkt);
+
+    case TLS_ST_CR_REQUEST_CONNECTION_ID:
+        return tls_process_request_connection_id(s, pkt);
+
     case TLS_ST_CR_ACK:
         return dtls_process_ack(s, pkt);
     }
