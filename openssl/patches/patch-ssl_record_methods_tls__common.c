$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/record/methods/tls_common.c.orig
+++ ssl/record/methods/tls_common.c
@@ -1187,7 +1187,67 @@ int tls_set_options(OSSL_RECORD_LAYER *rl, const OSSL_PARAM *options)
             ERR_raise(ERR_LIB_SSL, SSL_R_FAILED_TO_GET_PARAMETER);
             return 0;
         }
+        /* Our CID, to frame later epochs' records with (frame_cid) */
+        p = OSSL_PARAM_locate_const(options,
+            OSSL_LIBSSL_RECORD_LAYER_PARAM_DTLS_CID);
+        if (p != NULL && rl->cid_len == 0) {
+            void *cid = NULL;
+            size_t len = 0;
+
+            if (!OSSL_PARAM_get_octet_string(p, &cid, 0, &len)
+                || len > SSL_DTLS_CID_MAX_LEN) {
+                OPENSSL_free(cid);
+                ERR_raise(ERR_LIB_SSL, SSL_R_FAILED_TO_GET_PARAMETER);
+                return 0;
+            }
+            OPENSSL_free(rl->frame_cid);
+            rl->frame_cid = cid;
+            rl->frame_cid_len = len;
+        }
+        /*
+         * The further CIDs of our own the peer may use (RFC 9147 section
+         * 9), all of the record layer's CID length.
+         */
+        p = OSSL_PARAM_locate_const(options,
+            OSSL_LIBSSL_RECORD_LAYER_PARAM_DTLS_CID_MORE);
+        if (p != NULL) {
+            void *more = NULL;
+            size_t len = 0;
+
+            if (rl->cid_len == 0
+                || !OSSL_PARAM_get_octet_string(p, &more, 0, &len)
+                || len % rl->cid_len != 0) {
+                OPENSSL_free(more);
+                ERR_raise(ERR_LIB_SSL, SSL_R_FAILED_TO_GET_PARAMETER);
+                return 0;
+            }
+            OPENSSL_free(rl->cid_more);
+            rl->cid_more = more;
+            rl->cid_more_num = len / rl->cid_len;
+        }
     } else {
+        /*
+         * The CID records are written with, when the peer has given a new
+         * one (RFC 9147 section 9, "cid_immediate").  Only a record layer
+         * that writes a CID already changes it.
+         */
+        p = OSSL_PARAM_locate_const(options,
+            OSSL_LIBSSL_RECORD_LAYER_PARAM_DTLS_CID);
+        if (p != NULL) {
+            void *cid = NULL;
+            size_t len = 0;
+
+            if (rl->cid_len == 0
+                || !OSSL_PARAM_get_octet_string(p, &cid, 0, &len)
+                || len == 0 || len > SSL_DTLS_CID_MAX_LEN) {
+                OPENSSL_free(cid);
+                ERR_raise(ERR_LIB_SSL, SSL_R_FAILED_TO_GET_PARAMETER);
+                return 0;
+            }
+            OPENSSL_free(rl->cid);
+            rl->cid = cid;
+            rl->cid_len = len;
+        }
         p = OSSL_PARAM_locate_const(options,
             OSSL_LIBSSL_RECORD_LAYER_PARAM_BLOCK_PADDING);
         if (p != NULL && !OSSL_PARAM_get_size_t(p, &rl->block_padding)) {
@@ -1281,6 +1341,24 @@ int tls_int_new_record_layer(OSSL_LIB_CTX *libctx, const char *propq, int vers,
                     ERR_raise(ERR_LIB_SSL, SSL_R_FAILED_TO_GET_PARAMETER);
                     goto err;
                 }
+            } else if (strcmp(p->key,
+                           OSSL_LIBSSL_RECORD_LAYER_PARAM_DTLS_CID)
+                == 0) {
+                void *cid = NULL;
+
+                /*
+                 * RFC 9146 section 4: a tls12_cid record's "CID field is
+                 * present and contains one or more bytes", at most 2^8-1
+                 * (section 3).  A zero length CID is never passed here.
+                 */
+                if (!OSSL_PARAM_get_octet_string(p, &cid, 0, &rl->cid_len)
+                    || rl->cid_len == 0 || rl->cid_len > SSL_DTLS_CID_MAX_LEN) {
+                    OPENSSL_free(cid);
+                    rl->cid_len = 0;
+                    ERR_raise(ERR_LIB_SSL, SSL_R_FAILED_TO_GET_PARAMETER);
+                    goto err;
+                }
+                rl->cid = cid;
             } else {
                 ERR_raise(ERR_LIB_SSL, SSL_R_UNKNOWN_MANDATORY_PARAMETER);
                 goto err;
@@ -1448,6 +1526,10 @@ static void tls_int_free(OSSL_RECORD_LAYER *rl)
 #endif
     OPENSSL_free(rl->iv);
     OPENSSL_free(rl->nonce);
+    OPENSSL_free(rl->cid);
+    OPENSSL_free(rl->frame_cid);
+    OPENSSL_free(rl->cid_more);
+    OPENSSL_cleanse(rl->cid_iv, sizeof(rl->cid_iv));
 
     TLS_RL_RECORD_release(rl->rrec, SSL_MAX_PIPELINES);
 
@@ -1723,16 +1805,19 @@ int tls_post_encryption_processing_default(OSSL_RECORD_LAYER *rl,
     recordstart += tls_get_record_body_alignment_offset(rl, recordstart);
 
     if (rl->isdtls)
-        rechdrlen = dtls_get_rec_header_size(*recordstart);
+        rechdrlen = dtls_get_rec_header_size(rl, *recordstart);
     else
         rechdrlen = SSL3_RT_HEADER_LENGTH;
 
     if (rl->isdtls && DTLS13_UNI_HDR_FIX_BITS_IS_SET(*recordstart)) {
         size_t seqnumlen = DTLS13_UNI_HDR_SEQ_BIT_IS_SET(*recordstart) ? 2 : 1;
+        /* RFC 9147 section 4, Figure 3: the sequence number follows any CID */
+        size_t seqoff = DTLS13_UNI_HDR_SEQ_OFF
+            + (DTLS13_UNI_HDR_CID_BIT_IS_SET(*recordstart) ? rl->cid_len : 0);
 
-        if (!ossl_assert(DTLS13_UNI_HDR_SEQ_OFF + seqnumlen <= rechdrlen)
+        if (!ossl_assert(seqoff + seqnumlen <= rechdrlen)
             || (rl->sn_enc_ctx != NULL
-                && !dtls_crypt_sequence_number(rl->sn_enc_ctx, recordstart + DTLS13_UNI_HDR_SEQ_OFF,
+                && !dtls_crypt_sequence_number(rl->sn_enc_ctx, recordstart + seqoff,
                     seqnumlen, recordstart + rechdrlen))) {
             RLAYERfatal(rl, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
             return 0;
@@ -1745,7 +1830,8 @@ int tls_post_encryption_processing_default(OSSL_RECORD_LAYER *rl,
         rl->msg_callback(1, thiswr->rec_version, SSL3_RT_HEADER, recordstart,
             rechdrlen, rl->cbarg);
 
-        if (rl->version == version1_3 && rl->enc_ctx != NULL) {
+        if ((rl->version == version1_3 || rl->cid_len != 0)
+            && rl->enc_ctx != NULL) {
             unsigned char ctype = thistempl->type;
 
             rl->msg_callback(1, thiswr->rec_version, SSL3_RT_INNER_CONTENT_TYPE,
