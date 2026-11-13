$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/record/methods/tls13_meth.c.orig
+++ ssl/record/methods/tls13_meth.c
@@ -111,7 +111,8 @@ static int tls13_cipher(OSSL_RECORD_LAYER *rl, TLS_RL_RECORD *recs,
     size_t macsize)
 {
     EVP_CIPHER_CTX *enc_ctx;
-    unsigned char recheader[SSL3_RT_HEADER_LENGTH];
+    /* A DTLS 1.3 unified header may carry a CID (RFC 9147 section 4) */
+    unsigned char recheader[SSL3_RT_HEADER_LENGTH + SSL_DTLS_CID_MAX_LEN];
     unsigned char tag[EVP_MAX_MD_SIZE];
     size_t nonce_len, offset, loop, hdrlen, taglen, exphdrlen;
     int isdtls, sbit = 0, addlen;
@@ -217,7 +218,7 @@ static int tls13_cipher(OSSL_RECORD_LAYER *rl, TLS_RL_RECORD *recs,
      *   tls13_post_process_record() for incoming records.
      */
     if (isdtls) {
-        exphdrlen = dtls_get_rec_header_size(rec->type);
+        exphdrlen = dtls_get_rec_header_size(rl, rec->type);
         sbit = DTLS13_UNI_HDR_SEQ_BIT_IS_SET(rec->type);
         addlen = DTLS13_UNI_HDR_LEN_BIT_IS_SET(rec->type);
         /* Match the truncated value encoded in the unified header. */
@@ -228,16 +229,29 @@ static int tls13_cipher(OSSL_RECORD_LAYER *rl, TLS_RL_RECORD *recs,
     }
 
     /*
-     * Reject unsupported CID before WPACKET setup so cleanup cannot touch
-     * an uninitialised packet.
+     * A record layer without a CID never frames a header with the C bit (see
+     * dtls_get_more_records()); check before WPACKET setup so cleanup cannot
+     * touch an uninitialised packet.
      */
-    if (isdtls && !ossl_assert(!DTLS13_UNI_HDR_CID_BIT_IS_SET(rec->type))) {
+    if (isdtls
+        && !ossl_assert(!DTLS13_UNI_HDR_CID_BIT_IS_SET(rec->type)
+            || (rl->cid_len != 0 && (sending || rec->cid != NULL)))) {
         RLAYERfatal(rl, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
         return 0;
     }
 
     if (!WPACKET_init_static_len(&wpkt, recheader, sizeof(recheader), 0)
         || !WPACKET_put_bytes_u8(&wpkt, rec->type)
+        /*
+         * RFC 9147 section 4: "The entire header value shown in Figure 4
+         * (but prior to record number encryption ...) is used as the
+         * additional data value for the AEAD function", the CID with it.
+         * A received record may carry any of the CIDs we gave out
+         * (section 9), so it is the one in its header.
+         */
+        || (isdtls && DTLS13_UNI_HDR_CID_BIT_IS_SET(rec->type)
+            && !WPACKET_memcpy(&wpkt, sending ? rl->cid : rec->cid,
+                rl->cid_len))
         || (isdtls
             && (sbit ? !WPACKET_put_bytes_u16(&wpkt, seqnum)
                      : !WPACKET_put_bytes_u8(&wpkt, seqnum)))
@@ -392,8 +406,15 @@ static uint8_t tls13_get_record_type(OSSL_RECORD_LAYER *rl,
         const unsigned char sbit = DTLS13_UNI_HDR_SEQ_BIT;
         const unsigned char lbit = DTLS13_UNI_HDR_LEN_BIT;
         const unsigned char epochbits = DTLS13_UNI_HDR_EPOCH_BITS_MASK & rl->epoch;
+        /*
+         * RFC 9147 section 4: "The C bit (0x10) is set if the Connection ID
+         * is present", as dtls_prepare_record_header() writes it.  This byte
+         * starts the additional data (tls13_cipher()), which has to match
+         * the header on the wire.
+         */
+        const unsigned char cbit = rl->cid_len != 0 ? DTLS13_UNI_HDR_CID_BIT : 0;
 
-        return fixed | sbit | lbit | epochbits;
+        return fixed | cbit | sbit | lbit | epochbits;
     }
 
     return SSL3_RT_APPLICATION_DATA;
