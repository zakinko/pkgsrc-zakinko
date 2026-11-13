$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/record/rec_layer_d1.c.orig
+++ ssl/record/rec_layer_d1.c
@@ -349,6 +349,10 @@ start:
                 }
                 return ret;
             }
+#ifndef OPENSSL_NO_SOCK
+            /* RFC 9146 section 6: the record has passed verification */
+            ossl_dtls_note_record(sc, rr->epoch, rr->seq_num);
+#endif
             rr->off = 0;
             sc->rlayer.num_recs++;
         } while (sc->rlayer.rrlmethod->processed_read_pending(sc->rlayer.rrl)
@@ -375,6 +379,7 @@ start:
             && (current_state == TLS_ST_CW_FINISHED
                 || current_state == TLS_ST_CW_KEY_UPDATE
                 || current_state == TLS_ST_SW_KEY_UPDATE
+                || ossl_statem_is_cid_update_write(current_state)
                 || current_state == TLS_ST_SW_SESSION_TICKET
                 || (current_state == TLS_ST_OK && SSL_in_init(s)))
             && rr->type == SSL3_RT_APPLICATION_DATA)) {
@@ -491,6 +496,25 @@ start:
      * then it was unexpected (Hello Request or Client Hello).
      */
 
+#ifndef OPENSSL_NO_SOCK
+    /*
+     * RFC 9853: a return_routability_check record, once RRC is negotiated
+     * ("The client and server MUST NOT use RRC unless both sides have
+     * successfully exchanged rrc extensions", section 3).  One that is not
+     * protected was not sent "using the currently active security context"
+     * (section 4) and is dropped as invalid.  Without RRC it is an
+     * unexpected record, below.
+     */
+    if (rr->type == SSL3_RT_RETURN_ROUTABILITY_CHECK
+        && sc->ext.dtls_cid.rrc_negotiated) {
+        if (rr->epoch != 0)
+            ossl_dtls_rrc_record(sc, rr->data + rr->off, rr->length);
+        if (!ssl_release_record(sc, rr, 0))
+            return -1;
+        goto start;
+    }
+#endif
+
     if (rr->type == SSL3_RT_ALERT) {
         unsigned int alert_level, alert_descr;
         const unsigned char *alert_bytes = rr->data + rr->off;
