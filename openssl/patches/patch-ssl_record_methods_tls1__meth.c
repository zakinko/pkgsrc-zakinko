$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/record/methods/tls1_meth.c.orig
+++ ssl/record/methods/tls1_meth.c
@@ -16,6 +16,16 @@
 #include "../record_local.h"
 #include "recmethod_local.h"
 
+/* RFC 7905 section 2: "SecurityParameters.fixed_iv_length is twelve bytes" */
+#define DTLS_CID_CHACHA_IV_LEN 12
+/* RFC 9146 section 5: "seq_num_placeholder:  8 bytes of 0xff." */
+#define DTLS_CID_SEQ_NUM_PLACEHOLDER_LEN 8
+/* 8 + tls12_cid + cid_length + tls12_cid + version(2) + epoch(2) + seq(6) */
+#define DTLS_CID_MAC_HEADER_FIXED_LEN (DTLS_CID_SEQ_NUM_PLACEHOLDER_LEN + 13)
+/* ... + cid + a two byte length */
+#define DTLS_CID_MAC_HEADER_MAX_LEN \
+    (DTLS_CID_MAC_HEADER_FIXED_LEN + SSL_DTLS_CID_MAX_LEN + 2)
+
 static int tls1_set_crypto_state(OSSL_RECORD_LAYER *rl, int level,
     unsigned char *snkey,
     unsigned char *key, size_t keylen,
@@ -166,6 +176,44 @@ static int tls1_set_crypto_state(OSSL_RECORD_LAYER *rl, int level,
         rl->eivlen = (size_t)eivlen;
     }
 
+    if (rl->cid_len != 0) {
+        int mode = EVP_CIPHER_get_mode(ciph);
+        int aead = (EVP_CIPHER_get_flags(ciph) & EVP_CIPH_FLAG_AEAD_CIPHER) != 0;
+
+        /*
+         * RFC 9146 sections 5.2 (block cipher with Encrypt-then-MAC) and 5.3
+         * (AEAD) are implemented, 5.1 (MAC-then-encrypt) is not; see
+         * tls_dtls_cid_record_protection_ok(), which keeps the handshake from
+         * getting here with one.  A "composite" cipher (AES-CBC-HMAC-SHA)
+         * carries the AEAD flag but is CBC MAC-then-encrypt underneath.
+         */
+        if (!(aead && mode != EVP_CIPH_CBC_MODE)
+            && !(rl->use_etm && mode == EVP_CIPH_CBC_MODE)) {
+            ERR_raise(ERR_LIB_SSL, SSL_R_CONNECTION_ID_NOT_SUPPORTED_WITH_CIPHER);
+            return OSSL_RECORD_RETURN_FATAL;
+        }
+        if (aead) {
+            /*
+             * The fixed part of the nonce: "salt[4]" for GCM (RFC 5288
+             * section 3) and CCM (RFC 6655 section 3), the 12 byte write IV
+             * for ChaCha20-Poly1305 (RFC 7905 section 2).
+             */
+            size_t want = DTLS_CID_CHACHA_IV_LEN;
+
+            if (mode == EVP_CIPH_GCM_MODE)
+                want = EVP_GCM_TLS_FIXED_IV_LEN;
+            else if (mode == EVP_CIPH_CCM_MODE)
+                want = EVP_CCM_TLS_FIXED_IV_LEN;
+
+            if (ivlen != want || ivlen > sizeof(rl->cid_iv)) {
+                ERR_raise(ERR_LIB_SSL, ERR_R_INTERNAL_ERROR);
+                return OSSL_RECORD_RETURN_FATAL;
+            }
+            memcpy(rl->cid_iv, iv, ivlen);
+            rl->cid_ivlen = ivlen;
+        }
+    }
+
     return OSSL_RECORD_RETURN_SUCCESS;
 }
 
@@ -194,6 +242,193 @@ static int setup_record_header(const OSSL_RECORD_LAYER *rl, TLS_RL_RECORD *rec,
     return 1;
 }
 
+/*-
+ * Write the part that RFC 9146 section 5 puts in front of the protected data
+ * of a tls12_cid record, the same for the MAC of sections 5.1 and 5.2 and the
+ * additional data of section 5.3:
+ *
+ *     seq_num_placeholder +
+ *     tls12_cid +
+ *     cid_length +
+ *     tls12_cid +
+ *     DTLSCiphertext.version +
+ *     epoch +
+ *     sequence_number +
+ *     cid +
+ *     <length>
+ *
+ * where <length> is length_of_DTLSInnerPlaintext in 5.1 and 5.3 and
+ * DTLSCiphertext.length in 5.2.  The caller passes it in |length|.  "The
+ * epoch and sequence_number are now fed into the MAC in the same order as
+ * they appear on the wire" (5.1).
+ */
+static int dtls_cid_write_header(const OSSL_RECORD_LAYER *rl,
+    const TLS_RL_RECORD *rec, size_t length,
+    unsigned char *buf, size_t buflen, size_t *outlen)
+{
+    WPACKET hdr;
+    int ok;
+
+    if (!WPACKET_init_static_len(&hdr, buf, buflen, 0))
+        return 0;
+    ok = WPACKET_memset(&hdr, 0xff, DTLS_CID_SEQ_NUM_PLACEHOLDER_LEN)
+        && WPACKET_put_bytes_u8(&hdr, SSL3_RT_TLS12_CID)
+        /* "cid_length:  The length (in bytes) of the negotiated CID (one-byte integer)" */
+        && WPACKET_put_bytes_u8(&hdr, rl->cid_len)
+        && WPACKET_put_bytes_u8(&hdr, SSL3_RT_TLS12_CID)
+        && WPACKET_put_bytes_u16(&hdr, rec->rec_version)
+        && WPACKET_put_bytes_u16(&hdr, rl->epoch)
+        && WPACKET_put_bytes_u48(&hdr, rl->sequence)
+        && WPACKET_memcpy(&hdr, rl->cid, rl->cid_len)
+        /* "two-byte integer"; 5 says the inner plaintext "MUST NOT exceed 2^14" */
+        && WPACKET_put_bytes_u16(&hdr, length)
+        && WPACKET_finish(&hdr)
+        && WPACKET_get_total_written(&hdr, outlen);
+    if (!ok)
+        WPACKET_cleanup(&hdr);
+    return ok;
+}
+
+/*
+ * Encrypt or decrypt one tls12_cid record with an AEAD cipher (RFC 9146
+ * section 5.3).  The additional data is not the 13 bytes of
+ * EVP_CTRL_AEAD_TLS1_AAD, so the cipher is used through the generic AEAD
+ * calls and the nonce, which the TLS mode of the cipher would otherwise build
+ * itself, is built here.  Returns 1 on success and 0 when the record is
+ * publicly invalid, fails authentication, or on internal error (in which case
+ * RLAYERfatal() has been called), as tls1_cipher() does.
+ */
+static int dtls_cid_aead_cipher(OSSL_RECORD_LAYER *rl, TLS_RL_RECORD *rec,
+    int sending)
+{
+    EVP_CIPHER_CTX *ds = rl->enc_ctx;
+    int mode = EVP_CIPHER_CTX_get_mode(ds);
+    unsigned char nonce[EVP_MAX_IV_LENGTH];
+    unsigned char aad[DTLS_CID_MAC_HEADER_MAX_LEN];
+    unsigned char seq64[8];
+    unsigned char *explicit, *data, *tag;
+    size_t aadlen, inlen, i;
+    int outl;
+
+    /*
+     * RFC 6655 section 3 and RFC 7905 section 2: "In DTLS, the 64-bit
+     * seq_num is the 16-bit epoch concatenated with the 48-bit seq_num."
+     */
+    for (i = 0; i < 2; i++)
+        seq64[i] = (unsigned char)(rl->epoch >> (8 * (1 - i)));
+    for (i = 0; i < 6; i++)
+        seq64[2 + i] = (unsigned char)(rl->sequence >> (8 * (5 - i)));
+
+    /*
+     * |rec| holds nonce_explicit (|rl->eivlen| bytes, none for
+     * ChaCha20-Poly1305), then the DTLSInnerPlaintext or its ciphertext,
+     * then on reading the tag; on sending the tag goes after the ciphertext,
+     * into the room tls_prepare_for_encryption_default() left for it.
+     */
+    if (sending) {
+        if (rec->data != rec->input || rec->length < rl->eivlen) {
+            RLAYERfatal(rl, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+            return 0;
+        }
+        inlen = rec->length - rl->eivlen;
+    } else {
+        /* Publicly invalid: shorter than nonce_explicit plus the tag */
+        if (rec->length < rl->eivlen + rl->taglen)
+            return 0;
+        inlen = rec->length - rl->eivlen - rl->taglen;
+    }
+    explicit = rec->input;
+    data = rec->input + rl->eivlen;
+    tag = data + inlen;
+
+    if (mode == EVP_CIPH_GCM_MODE || mode == EVP_CIPH_CCM_MODE) {
+        /*
+         * RFC 5288 section 3 and RFC 6655 section 3: nonce = salt[4] ||
+         * nonce_explicit[8].  "Each value of the nonce_explicit MUST be
+         * distinct for each distinct invocation of the GCM encrypt function
+         * for any fixed key"; it "MAY be the 64-bit sequence number", which
+         * is distinct within an epoch, whose keys are its own.
+         */
+        size_t fixedlen = mode == EVP_CIPH_GCM_MODE ? EVP_GCM_TLS_FIXED_IV_LEN
+                                                    : EVP_CCM_TLS_FIXED_IV_LEN;
+        size_t explicitlen = mode == EVP_CIPH_GCM_MODE
+            ? EVP_GCM_TLS_EXPLICIT_IV_LEN
+            : EVP_CCM_TLS_EXPLICIT_IV_LEN;
+
+        if (!ossl_assert(rl->eivlen == explicitlen
+                && rl->eivlen == sizeof(seq64)
+                && rl->cid_ivlen == fixedlen)) {
+            RLAYERfatal(rl, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+            return 0;
+        }
+        if (sending)
+            memcpy(explicit, seq64, sizeof(seq64));
+        memcpy(nonce, rl->cid_iv, rl->cid_ivlen);
+        memcpy(nonce + rl->cid_ivlen, explicit, rl->eivlen);
+    } else {
+        /*
+         * RFC 7905 section 2: the sequence number "padded on the left with
+         * four 0x00 bytes" and "XORed with the client_write_IV ... or
+         * server_write_IV".
+         */
+        if (!ossl_assert(rl->eivlen == 0
+                && rl->cid_ivlen == DTLS_CID_CHACHA_IV_LEN)) {
+            RLAYERfatal(rl, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+            return 0;
+        }
+        memcpy(nonce, rl->cid_iv, DTLS_CID_CHACHA_IV_LEN);
+        for (i = 0; i < sizeof(seq64); i++)
+            nonce[DTLS_CID_CHACHA_IV_LEN - sizeof(seq64) + i] ^= seq64[i];
+    }
+
+    /*
+     * RFC 9146 section 5.3: the additional data ends with
+     * length_of_DTLSInnerPlaintext, which these ciphers do not change.
+     */
+    if (!dtls_cid_write_header(rl, rec, inlen, aad, sizeof(aad), &aadlen)) {
+        RLAYERfatal(rl, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+        return 0;
+    }
+
+    if (inlen > INT_MAX
+        || !EVP_CipherInit_ex(ds, NULL, NULL, NULL, nonce, sending)
+        /* CCM takes the tag before the data, and the data length up front */
+        || (!sending
+            && EVP_CIPHER_CTX_ctrl(ds, EVP_CTRL_AEAD_SET_TAG, (int)rl->taglen,
+                   tag)
+                <= 0)
+        || (mode == EVP_CIPH_CCM_MODE
+            && !EVP_CipherUpdate(ds, NULL, &outl, NULL, (int)inlen))
+        || !EVP_CipherUpdate(ds, NULL, &outl, aad, (int)aadlen)) {
+        RLAYERfatal(rl, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+        return 0;
+    }
+    /* A failure from here on, when reading, is a record that is not genuine */
+    if (!EVP_CipherUpdate(ds, data, &outl, data, (int)inlen)
+        || (size_t)outl != inlen
+        || (mode != EVP_CIPH_CCM_MODE
+            && !EVP_CipherFinal_ex(ds, data + outl, &outl))) {
+        if (sending)
+            RLAYERfatal(rl, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+        return 0;
+    }
+    if (sending) {
+        if (EVP_CIPHER_CTX_ctrl(ds, EVP_CTRL_AEAD_GET_TAG, (int)rl->taglen,
+                tag)
+            <= 0) {
+            RLAYERfatal(rl, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+            return 0;
+        }
+        rec->length += rl->taglen;
+    } else {
+        rec->data += rl->eivlen;
+        rec->input += rl->eivlen;
+        rec->length = inlen;
+    }
+
+    return 1;
+}
+
 #define MAX_PADDING 256
 /*-
  * tls1_cipher encrypts/decrypts |n_recs| in |recs|. Calls RLAYERfatal on
@@ -239,6 +474,20 @@ static int tls1_cipher(OSSL_RECORD_LAYER *rl, TLS_RL_RECORD *recs,
 
     enc = EVP_CIPHER_CTX_get0_cipher(rl->enc_ctx);
 
+    /*
+     * A tls12_cid record under an AEAD cipher (RFC 9146 section 5.3); the
+     * record layer was only set up with a CID for a true AEAD or for CBC with
+     * Encrypt-then-MAC (tls1_set_crypto_state()).
+     */
+    if (rl->cid_len != 0
+        && (EVP_CIPHER_get_flags(enc) & EVP_CIPH_FLAG_AEAD_CIPHER) != 0) {
+        if (n_recs != 1) {
+            RLAYERfatal(rl, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+            return 0;
+        }
+        return dtls_cid_aead_cipher(rl, recs, sending);
+    }
+
     if (sending) {
         int ivlen;
 
@@ -439,6 +688,8 @@ static int tls1_mac(OSSL_RECORD_LAYER *rl, TLS_RL_RECORD *rec, unsigned char *md
     EVP_MD_CTX *hmac = NULL, *mac_ctx;
     EVP_PKEY_CTX *pkctx;
     unsigned char header[13];
+    unsigned char cidheader[DTLS_CID_MAC_HEADER_MAX_LEN];
+    size_t cidheaderlen = 0;
     int t;
     int ret = 0;
 
@@ -465,8 +716,22 @@ static int tls1_mac(OSSL_RECORD_LAYER *rl, TLS_RL_RECORD *rec, unsigned char *md
         && EVP_MD_CTX_ctrl(mac_ctx, EVP_MD_CTRL_TLSTREE, 0, seq) <= 0)
         goto end;
 
-    if (!setup_record_header(rl, rec, header, sizeof(header)))
+    /*
+     * RFC 9146 section 5.2 (Encrypt-then-MAC): "DTLSCiphertext.length + IV +
+     * ENC(content + padding + padding_length)".  DTLSCiphertext.length is
+     * taken as for Encrypt-then-MAC without a CID, the length of what the MAC
+     * covers after the header (RFC 7366 section 3), which is |rec->length|
+     * here.  Section 5.1 (MAC-then-encrypt) is refused in
+     * tls1_set_crypto_state().
+     */
+    if (rl->cid_len != 0) {
+        if (!ossl_assert(rl->use_etm)
+            || !dtls_cid_write_header(rl, rec, rec->length, cidheader,
+                sizeof(cidheader), &cidheaderlen))
+            goto end;
+    } else if (!setup_record_header(rl, rec, header, sizeof(header))) {
         goto end;
+    }
 
     if (!sending && !rl->use_etm
         && EVP_CIPHER_CTX_get_mode(rl->enc_ctx) == EVP_CIPH_CBC_MODE
@@ -487,7 +752,10 @@ static int tls1_mac(OSSL_RECORD_LAYER *rl, TLS_RL_RECORD *rec, unsigned char *md
             goto end;
     }
 
-    if (EVP_DigestSignUpdate(mac_ctx, header, sizeof(header)) <= 0
+    if ((cidheaderlen != 0
+                ? EVP_DigestSignUpdate(mac_ctx, cidheader, cidheaderlen)
+                : EVP_DigestSignUpdate(mac_ctx, header, sizeof(header)))
+            <= 0
         || EVP_DigestSignUpdate(mac_ctx, rec->input, rec->length) <= 0
         || EVP_DigestSignFinal(mac_ctx, md, &md_size) <= 0)
         goto end;
@@ -639,7 +907,7 @@ const struct record_functions_st dtls_1_funcs = {
     tls_default_read_n,
     dtls_get_more_records,
     NULL,
-    NULL,
+    dtls_cid_post_process_record,
     NULL,
     tls_write_records_default,
     /*
@@ -650,9 +918,9 @@ const struct record_functions_st dtls_1_funcs = {
     tls_allocate_write_buffers_default,
     /* Don't use tls1_initialise_write_packets for same reason as above */
     tls_initialise_write_packets_default,
-    NULL,
+    dtls_cid_get_record_type,
     dtls_prepare_record_header,
-    NULL,
+    dtls_cid_add_record_padding,
     tls_prepare_for_encryption_default,
     dtls_post_encryption_processing,
     NULL
