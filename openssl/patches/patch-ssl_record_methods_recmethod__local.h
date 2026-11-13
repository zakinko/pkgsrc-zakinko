$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/record/methods/recmethod_local.h.orig
+++ ssl/record/methods/recmethod_local.h
@@ -79,6 +79,12 @@ typedef struct tls_rl_record_st {
     /* sequence number, needed by DTLS1 */
     /* r */
     uint64_t seq_num;
+    /*
+     * The CID a received DTLS 1.3 record carried, pointing into the record
+     * layer's |cid| or |cid_more|; NULL when it had none
+     */
+    /* r */
+    const unsigned char *cid;
 } TLS_RL_RECORD;
 
 /* Macros/functions provided by the TLS_RL_RECORD component */
@@ -332,6 +338,37 @@ struct ossl_record_layer_st {
     /* TLSv1.0/TLSv1.1/TLSv1.2 */
     int use_etm;
 
+    /*
+     * DTLS 1.2 Connection ID (RFC 9146).  When |cid_len| is not zero every
+     * record of this epoch uses the tls12_cid format of section 4, Figure 3,
+     * and carries |cid|: the CID we expect in a read record layer, the
+     * peer's CID in a write record layer.  An AEAD cipher is then driven
+     * through the generic AEAD interface, because the additional data of
+     * section 5.3 is not the 13 bytes EVP_CTRL_AEAD_TLS1_AAD takes, and the
+     * nonce is built here from |cid_iv| (the fixed part, "salt" for GCM and
+     * CCM, the whole write IV for ChaCha20-Poly1305).
+     */
+    unsigned char *cid;
+    size_t cid_len;
+    /*
+     * A read record layer made before the CID was negotiated (DTLS 1.3
+     * epoch 0) gets the CID we sent here, only to find the end of the
+     * records of later epochs that it keeps for the next record layer
+     * (see dtls_get_more_records()).  Nothing is decrypted with it.
+     */
+    unsigned char *frame_cid;
+    size_t frame_cid_len;
+    /*
+     * Further CIDs of our own that a read record layer accepts, each
+     * |cid_len| bytes, |cid_more_num| of them: DTLS 1.3 lets the peer use
+     * any CID we gave it in a NewConnectionId message (RFC 9147 section 9,
+     * "either an existing or new CID MAY be used").
+     */
+    unsigned char *cid_more;
+    size_t cid_more_num;
+    unsigned char cid_iv[EVP_MAX_IV_LENGTH];
+    size_t cid_ivlen;
+
     /* Flags for GOST ciphers */
     int stream_mac;
     int tlstree;
@@ -474,7 +511,59 @@ int tls_get_more_records(OSSL_RECORD_LAYER *rl);
 uint64_t dtls13_reconstruct_seq_num(uint64_t max_seq_num, uint64_t truncated,
     size_t seqlen);
 
-size_t dtls_get_rec_header_size(uint8_t hdr_first_byte);
+/**
+ * @brief Get the length of a DTLS record header from its first byte.
+ * @param rl the record layer the record belongs to; it gives the length of
+ * the CID in a tls12_cid header (RFC 9146 section 4)
+ * @param hdr_first_byte the first byte of the record
+ * @returns the header length in bytes
+ */
+size_t dtls_get_rec_header_size(const OSSL_RECORD_LAYER *rl,
+    uint8_t hdr_first_byte);
+
+/**
+ * @brief Get the outer content type of a DTLS 1.2 record to write.
+ * @param rl the write record layer
+ * @param template the record to write
+ * @returns tls12_cid when @p rl writes records with a CID (RFC 9146
+ * section 4), the template's type otherwise
+ */
+uint8_t dtls_cid_get_record_type(OSSL_RECORD_LAYER *rl,
+    OSSL_RECORD_TEMPLATE *template);
+
+/**
+ * @brief Append the real_type of a DTLSInnerPlaintext (RFC 9146 section 4,
+ * Figure 2) to a DTLS 1.2 record written with a CID; nothing otherwise.
+ * @param rl the write record layer
+ * @param thistempl the record being written
+ * @param thispkt the packet the record is written into
+ * @param thiswr the record
+ * @returns 1 on success, 0 on error (RLAYERfatal() called)
+ */
+int dtls_cid_add_record_padding(OSSL_RECORD_LAYER *rl,
+    OSSL_RECORD_TEMPLATE *thistempl,
+    WPACKET *thispkt,
+    TLS_RL_RECORD *thiswr);
+
+/**
+ * @brief Take a decrypted DTLS 1.2 record read with a CID apart into its
+ * content and real_type (RFC 9146 section 4, Figure 2); nothing for a record
+ * layer without a CID.
+ * @param rl the read record layer
+ * @param rec the decrypted record, updated in place
+ * @returns 1 on success, 0 on error (RLAYERfatal() called)
+ */
+int dtls_cid_post_process_record(OSSL_RECORD_LAYER *rl, TLS_RL_RECORD *rec);
+
+/**
+ * @brief Is @p cid, of the record layer's CID length, one of the CIDs a read
+ * record layer accepts?
+ * @param rl the read record layer
+ * @param cid the CID in a record
+ * @returns the CID of ours it matches, or NULL if none does
+ */
+const unsigned char *dtls_cid_is_ours(const OSSL_RECORD_LAYER *rl,
+    const unsigned char *cid);
 int dtls_crypt_sequence_number(EVP_CIPHER_CTX *ctx, unsigned char *seq, size_t seqlen,
     unsigned char *rec_data);
 int dtls_get_more_records(OSSL_RECORD_LAYER *rl);
