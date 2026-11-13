$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/record/methods/dtls_meth.c.orig
+++ ssl/record/methods/dtls_meth.c
@@ -113,14 +113,25 @@ static void dtls_set_in_init(OSSL_RECORD_LAYER *rl, int in_init)
     rl->in_init = in_init;
 }
 
-size_t dtls_get_rec_header_size(uint8_t hdr_first_byte)
+size_t dtls_get_rec_header_size(const OSSL_RECORD_LAYER *rl,
+    uint8_t hdr_first_byte)
 {
     size_t size = 0;
 
-    if (DTLS13_UNI_HDR_FIX_BITS_IS_SET(hdr_first_byte)
-        && ossl_assert(!DTLS13_UNI_HDR_CID_BIT_IS_SET(hdr_first_byte))) {
-        /* DTLSv1.3 unified record header */
+    if (hdr_first_byte == SSL3_RT_TLS12_CID && rl->version != DTLS1_3_VERSION
+        && rl->cid_len != 0) {
+        /* RFC 9146 section 4, Figure 3: the CID follows the sequence number */
+        size = DTLS1_RT_HEADER_LENGTH + rl->cid_len;
+    } else if (DTLS13_UNI_HDR_FIX_BITS_IS_SET(hdr_first_byte)) {
+        /*
+         * DTLSv1.3 unified record header (RFC 9147 section 4, Figure 3).
+         * With the C bit the CID follows the first byte, "length as
+         * negotiated"; a record layer without one never frames such a
+         * header (see dtls_get_more_records()).
+         */
         size = 1;
+        if (DTLS13_UNI_HDR_CID_BIT_IS_SET(hdr_first_byte))
+            size += rl->cid_len != 0 ? rl->cid_len : rl->frame_cid_len;
         size += DTLS13_UNI_HDR_SEQ_BIT_IS_SET(hdr_first_byte) ? 2 : 1;
         size += DTLS13_UNI_HDR_LEN_BIT_IS_SET(hdr_first_byte) ? 2 : 0;
     } else {
@@ -138,7 +149,7 @@ static int dtls_process_record(OSSL_RECORD_LAYER *rl, DTLS_BITMAP *bitmap)
     TLS_RL_RECORD *rr;
     int imac_size;
     size_t mac_size = 0;
-    size_t rechdrsize = dtls_get_rec_header_size(rl->packet[0]);
+    size_t rechdrsize = dtls_get_rec_header_size(rl, rl->packet[0]);
     unsigned char md[EVP_MAX_MD_SIZE];
     SSL_MAC_BUF macbuf = { NULL, 0 };
     int ret = 0;
@@ -277,9 +288,13 @@ static int dtls_process_record(OSSL_RECORD_LAYER *rl, DTLS_BITMAP *bitmap)
 
     /*
      * Check if the received packet overflows the current Max Fragment
-     * Length setting.
+     * Length setting.  A tls12_cid record still holds the DTLSInnerPlaintext
+     * here, whose length "MUST NOT exceed 2^14" (RFC 9146 section 5); its
+     * content is checked against the Max Fragment Length once the real_type
+     * and padding are off, in dtls_cid_post_process_record().
      */
-    if (rr->length > rl->max_frag_len) {
+    if (rl->cid_len != 0 ? rr->length > SSL3_RT_MAX_PLAIN_LENGTH
+                         : rr->length > rl->max_frag_len) {
         RLAYERfatal(rl, SSL_AD_RECORD_OVERFLOW, SSL_R_DATA_LENGTH_TOO_LONG);
         goto end;
     }
@@ -489,6 +504,34 @@ static int dtls13_plaintext_allows_type(const OSSL_RECORD_LAYER *rl, int type)
  * ssl->s3.rrec.data    - data
  * ssl->s3.rrec.length  - number of bytes
  */
+const unsigned char *dtls_cid_is_ours(const OSSL_RECORD_LAYER *rl,
+    const unsigned char *cid)
+{
+    size_t i;
+
+    if (memcmp(cid, rl->cid, rl->cid_len) == 0)
+        return rl->cid;
+    for (i = 0; i < rl->cid_more_num; i++)
+        if (memcmp(cid, rl->cid_more + i * rl->cid_len, rl->cid_len) == 0)
+            return rl->cid_more + i * rl->cid_len;
+    return NULL;
+}
+
+/*
+ * Drop the rest of the datagram the current record came from.  A record whose
+ * length cannot be found also leaves the place of the next record unknown, so
+ * whatever follows it in the datagram is not a record boundary to resume at.
+ * read_n() takes one datagram into |rbuf| and reads the next one only when
+ * |rbuf.left| is zero, so emptying it ends the datagram.  RFC 6347 section
+ * 4.1.2.7: "invalid records SHOULD be silently discarded".
+ */
+static void dtls_discard_datagram(OSSL_RECORD_LAYER *rl)
+{
+    rl->rbuf.offset += rl->rbuf.left;
+    rl->rbuf.left = 0;
+    rl->packet_length = 0;
+}
+
 int dtls_get_more_records(OSSL_RECORD_LAYER *rl)
 {
     int rret;
@@ -499,6 +542,7 @@ int dtls_get_more_records(OSSL_RECORD_LAYER *rl)
     unsigned char recseqnum[6];
     size_t recseqnumlen = 0;
     size_t rechdrlen = 0;
+    size_t bodyoff;
     size_t recseqnumoffs = 0;
     int buffered_record = 0;
     OSSL_RECORD_LAYER *crypto_rl;
@@ -603,13 +647,78 @@ again:
             recseqnumlen = sbitisset ? 2 : 1;
             recseqnumoffs = sizeof(recseqnum) - recseqnumlen;
 
-            if (/* OpenSSL does not support connection IDs: silently discard */
-                cbitisset
-                /*
+            /*
+             * RFC 9147 section 9: "If no CID is negotiated, then the
+             * receiver MUST reject any records it receives that contain a
+             * CID."  Without its length the rest of the datagram cannot be
+             * framed either.  Section 4: "If a Connection ID is negotiated,
+             * then it MUST be contained in all datagrams", so a record of
+             * this record layer's epoch without it is rejected the same
+             * way.  Records of other epochs are left to the epoch checks
+             * below: early data (epoch 1) is sent before the client knows
+             * the server's CID, and goes without.  A CID that is not ours
+             * is rejected too: "If the second or later record has a
+             * connection ID which does not correspond to the same
+             * association used for previous records, the rest of the
+             * datagram MUST be discarded."
+             */
+            /*
+             * A record layer from before the CID frames records with the CID
+             * we sent (frame_cid) and keeps them for the next one, which
+             * checks them in full.
+             */
+            size_t cidlen = rl->cid_len != 0 ? rl->cid_len : rl->frame_cid_len;
+
+            if ((cbitisset && cidlen == 0)
+                || (!cbitisset && rl->cid_len != 0
+                    && (rl->epoch & DTLS13_UNI_HDR_EPOCH_BITS_MASK) == eebits)) {
+                dtls_discard_datagram(rl);
+                rr->length = 0;
+                goto again;
+            }
+            if (cbitisset) {
+                PACKET cid;
+                size_t want = 1 + cidlen + recseqnumlen + (lbitisset ? 2 : 0);
+                size_t cidread = 0;
+
+                if (want > rl->packet_length) {
+                    size_t need = want - rl->packet_length;
+
+                    rret = rl->funcs->read_n(rl, need, need, 1, 0, &cidread);
+                    if (rret < OSSL_RECORD_RETURN_SUCCESS || cidread != need) {
+                        if (rl->alert != SSL_AD_NO_ALERT)
+                            return OSSL_RECORD_RETURN_FATAL;
+                        dtls_discard_datagram(rl);
+                        rr->length = 0;
+                        goto again;
+                    }
+                    nread += cidread;
+                    /* read_n() with extend may have moved rl->packet */
+                    if (!PACKET_buf_init(&dtlsrecord, rl->packet,
+                            rl->packet_length)
+                        || !PACKET_forward(&dtlsrecord, 1)) {
+                        dtls_discard_datagram(rl);
+                        rr->length = 0;
+                        goto again;
+                    }
+                }
+                if (!PACKET_get_sub_packet(&dtlsrecord, &cid, cidlen)
+                    || (rl->cid_len != 0
+                            ? (rr->cid = dtls_cid_is_ours(rl,
+                                   PACKET_data(&cid))) == NULL
+                            : memcmp(PACKET_data(&cid), rl->frame_cid, cidlen)
+                                != 0)) {
+                    dtls_discard_datagram(rl);
+                    rr->length = 0;
+                    goto again;
+                }
+            }
+
+            if (/*
                  * Naive approach? We expect sequence number to be filled already
                  * and then override the last bytes of the sequence number.
                  */
-                || !PACKET_copy_bytes(&dtlsrecord, recseqnum + recseqnumoffs, recseqnumlen)
+                !PACKET_copy_bytes(&dtlsrecord, recseqnum + recseqnumoffs, recseqnumlen)
                 /*
                  * rfc9147:
                  * The length field MAY be omitted by clearing the L bit, which means
@@ -654,6 +763,71 @@ again:
                     goto again;
                 }
             }
+        } else if (rr->type == SSL3_RT_TLS12_CID
+            && rl->version != DTLS1_3_VERSION) {
+            /*-
+             * RFC 9146 section 4, Figure 3:
+             *     struct {
+             *         ContentType outer_type = tls12_cid;
+             *         ProtocolVersion version;
+             *         uint16 epoch;
+             *         uint48 sequence_number;
+             *         opaque cid[cid_length];               // New field
+             *         uint16 length;
+             *         opaque enc_content[DTLSCiphertext.length];
+             *     } DTLSCiphertext;
+             * cid_length is not on the wire: it is the length of the CID we
+             * asked for (section 3).  Without one, as in a record layer
+             * that predates the handshake, the length field cannot be found.
+             */
+            PACKET cid;
+            size_t cidread = 0;
+
+            if (rl->cid_len == 0) {
+                dtls_discard_datagram(rl);
+                rr->length = 0;
+                goto again;
+            }
+            rret = rl->funcs->read_n(rl, rl->cid_len, rl->cid_len, 1, 0,
+                &cidread);
+            if (rret < OSSL_RECORD_RETURN_SUCCESS || cidread != rl->cid_len) {
+                if (rl->alert != SSL_AD_NO_ALERT) {
+                    /* read_n() called RLAYERfatal() */
+                    return OSSL_RECORD_RETURN_FATAL;
+                }
+                dtls_discard_datagram(rl);
+                rr->length = 0;
+                goto again;
+            }
+            nread += cidread;
+            /* read_n() with extend may have moved rl->packet */
+            if (!PACKET_buf_init(&dtlsrecord, rl->packet, rl->packet_length)
+                || !PACKET_forward(&dtlsrecord, 1)
+                || !PACKET_get_net_2(&dtlsrecord, &record_version)
+                || !PACKET_get_net_2(&dtlsrecord, &epoch)
+                || !PACKET_copy_bytes(&dtlsrecord, recseqnum, 6)
+                || !PACKET_get_sub_packet(&dtlsrecord, &cid, rl->cid_len)
+                || !PACKET_get_net_2(&dtlsrecord, &length)) {
+                dtls_discard_datagram(rl);
+                rr->length = 0;
+                goto again;
+            }
+            /*
+             * RFC 9146 section 3: "if the tls12_cid content type is set, then
+             * the CID is used to look up the connection and the security
+             * association."  This record layer serves one association; a CID
+             * other than ours names another one, or none, and the record is
+             * invalid here (RFC 6347 section 4.1.2.7).  The CID is not
+             * secret, so the comparison need not be constant time.
+             */
+            if (dtls_cid_is_ours(rl, PACKET_data(&cid)) == NULL) {
+                rr->length = 0;
+                rl->packet_length = 0;
+                goto again;
+            }
+            epoch64 = epoch;
+            recseqnumoffs = 0;
+            recseqnumlen = 6;
         } else {
             if (!PACKET_get_net_2(&dtlsrecord, &record_version)
                 || !PACKET_get_net_2(&dtlsrecord, &epoch)
@@ -666,6 +840,25 @@ again:
             epoch64 = epoch;
             recseqnumoffs = 0;
             recseqnumlen = 6;
+
+            /*
+             * RFC 9146 section 3: "If the tls12_cid content type is not set,
+             * then ... a check MUST be made to determine whether a
+             * non-zero-length CID is expected.  If a non-zero-length CID is
+             * expected for the retrieved association, then the datagram MUST
+             * be treated as invalid".  A CID is expected in the records of
+             * the epoch whose keys this record layer holds; records of other
+             * epochs are dealt with by the epoch checks below.  The section
+             * cites RFC 6347 section 4.1.2.1 for "invalid", which is the MAC
+             * section; the handling of invalid records is section 4.1.2.7,
+             * which says to discard them silently.  The whole datagram is
+             * invalid, so all of it goes.
+             */
+            if (rl->cid_len != 0 && epoch64 == rl->epoch) {
+                dtls_discard_datagram(rl);
+                rr->length = 0;
+                goto again;
+            }
         }
 
         rechdrlen = PACKET_data(&dtlsrecord) - rl->packet;
@@ -723,7 +916,19 @@ again:
 
     /* rl->rstate == SSL_ST_READ_BODY, get and decode the data */
 
-    if (rr->length > rl->packet_length - DTLS1_RT_HEADER_LENGTH) {
+    /*
+     * The header of a tls12_cid record is longer than DTLS1_RT_HEADER_LENGTH
+     * by the CID; measure what of the body is already in rl->packet from the
+     * real end of the header, which rl->packet[0] gives again on re-entry.
+     */
+    bodyoff = DTLS1_RT_HEADER_LENGTH;
+    if ((rl->version != DTLS1_3_VERSION && rl->cid_len != 0
+            && rl->packet[0] == SSL3_RT_TLS12_CID)
+        || ((rl->cid_len != 0 || rl->frame_cid_len != 0)
+            && DTLS13_UNI_HDR_FIX_BITS_IS_SET(rl->packet[0])
+            && DTLS13_UNI_HDR_CID_BIT_IS_SET(rl->packet[0])))
+        bodyoff = dtls_get_rec_header_size(rl, rl->packet[0]);
+    if (rr->length > rl->packet_length - bodyoff) {
         /* now rl->packet_length == DTLS1_RT_HEADER_LENGTH */
         more = rr->length - (nread - rechdrlen);
         rret = rl->funcs->read_n(rl, more, more, 1, 1, &nread);
@@ -1081,6 +1286,90 @@ err:
     return ret;
 }
 
+/*
+ * RFC 9146 section 4: once a non-zero length CID is in use, "the real content
+ * type is inside the encryption envelope": a record of this epoch is sent as
+ * tls12_cid(25) whatever its content.
+ */
+uint8_t dtls_cid_get_record_type(OSSL_RECORD_LAYER *rl,
+    OSSL_RECORD_TEMPLATE *template)
+{
+    if (rl->cid_len != 0)
+        return SSL3_RT_TLS12_CID;
+
+    return template->type;
+}
+
+/*-
+ * RFC 9146 section 4, Figure 2:
+ *     struct {
+ *         opaque content[length];
+ *         ContentType real_type;
+ *         uint8 zeros[length_of_padding];
+ *     } DTLSInnerPlaintext;
+ * The zeros are optional ("may appear") and none are sent.
+ */
+int dtls_cid_add_record_padding(OSSL_RECORD_LAYER *rl,
+    OSSL_RECORD_TEMPLATE *thistempl,
+    WPACKET *thispkt,
+    TLS_RL_RECORD *thiswr)
+{
+    if (rl->cid_len == 0)
+        return 1;
+
+    /*
+     * RFC 9146 section 5: length_of_DTLSInnerPlaintext "MUST NOT exceed
+     * 2^14".  ssl_get_max_send_fragment() keeps the content one byte short
+     * of that, so this does not fail unless that limit has been bypassed.
+     */
+    if (!ossl_assert(TLS_RL_RECORD_get_length(thiswr) < SSL3_RT_MAX_PLAIN_LENGTH)
+        || !WPACKET_put_bytes_u8(thispkt, thistempl->type)) {
+        RLAYERfatal(rl, SSL_AD_INTERNAL_ERROR, ERR_R_INTERNAL_ERROR);
+        return 0;
+    }
+    TLS_RL_RECORD_add_length(thiswr, 1);
+
+    return 1;
+}
+
+/*
+ * Take a decrypted tls12_cid record apart (RFC 9146 section 4, Figure 2) and
+ * leave its content and real_type in |rec|.  RFC 9146 section 4 refers to
+ * RFC 8446 section 5.4 for the padding, which says: "If a receiving
+ * implementation does not find a non-zero octet in the cleartext, it MUST
+ * terminate the connection with an "unexpected_message" alert."
+ */
+int dtls_cid_post_process_record(OSSL_RECORD_LAYER *rl, TLS_RL_RECORD *rec)
+{
+    size_t end;
+
+    if (rl->cid_len == 0)
+        return 1;
+
+    for (end = rec->length; end > 0 && rec->data[end - 1] == 0; end--)
+        continue;
+    if (end == 0) {
+        RLAYERfatal(rl, SSL_AD_UNEXPECTED_MESSAGE, SSL_R_BAD_RECORD_TYPE);
+        return 0;
+    }
+    rec->type = rec->data[end - 1];
+    rec->length = end - 1;
+
+    if (rec->length > rl->max_frag_len) {
+        RLAYERfatal(rl, SSL_AD_RECORD_OVERFLOW, SSL_R_DATA_LENGTH_TOO_LONG);
+        return 0;
+    }
+
+    if (rl->msg_callback != NULL) {
+        unsigned char ctype = (unsigned char)rec->type;
+
+        rl->msg_callback(0, rl->version, SSL3_RT_INNER_CONTENT_TYPE, &ctype,
+            1, rl->cbarg);
+    }
+
+    return 1;
+}
+
 int dtls_prepare_record_header(OSSL_RECORD_LAYER *rl,
     WPACKET *thispkt,
     OSSL_RECORD_TEMPLATE *templ,
@@ -1100,7 +1389,8 @@ int dtls_prepare_record_header(OSSL_RECORD_LAYER *rl,
 
     if (unifiedheader) {
         uint8_t fixedbits = 0x20;
-        uint8_t cbit = 0;
+        /* RFC 9147 section 4: "The C bit (0x10) is set if the Connection ID is present." */
+        uint8_t cbit = rl->cid_len != 0 ? DTLS13_UNI_HDR_CID_BIT : 0;
         uint8_t sbit = DTLS13_UNI_HDR_SEQ_BIT;
         uint8_t lbit = DTLS13_UNI_HDR_LEN_BIT;
         uint8_t ebits = rl->epoch & DTLS13_UNI_HDR_EPOCH_BITS_MASK;
@@ -1111,6 +1401,7 @@ int dtls_prepare_record_header(OSSL_RECORD_LAYER *rl,
         seqnum = rl->sequence & DTLS13_UNI_HDR_SEQ_MASK(sbit ? 2 : 1);
 
         if (!WPACKET_put_bytes_u8(thispkt, unifiedhdrbits)
+            || (cbit != 0 && !WPACKET_memcpy(thispkt, rl->cid, rl->cid_len))
             || (sbit ? !WPACKET_put_bytes_u16(thispkt, seqnum)
                      : !WPACKET_put_bytes_u8(thispkt, seqnum))
             || !WPACKET_start_sub_packet_u16(thispkt)
@@ -1126,6 +1417,9 @@ int dtls_prepare_record_header(OSSL_RECORD_LAYER *rl,
             || !WPACKET_put_bytes_u16(thispkt, templ->version)
             || !WPACKET_put_bytes_u16(thispkt, templ->epoch)
             || !WPACKET_put_bytes_u48(thispkt, templ->sequence_number)
+            /* RFC 9146 section 4, Figure 3: cid[cid_length] */
+            || (rectype == SSL3_RT_TLS12_CID
+                && !WPACKET_memcpy(thispkt, rl->cid, rl->cid_len))
             || !WPACKET_start_sub_packet_u16(thispkt)
             || (rl->eivlen > 0
                 && !WPACKET_allocate_bytes(thispkt, rl->eivlen, NULL))
@@ -1180,6 +1474,14 @@ static size_t dtls_get_max_record_overhead(OSSL_RECORD_LAYER *rl)
     if (rl->version == DTLS1_3_VERSION)
         contenttypelen = 1;
 
+    /*
+     * So does a DTLS 1.2 record with a CID (RFC 9146 section 4, Figure 2),
+     * whose header also carries the CID (Figure 3), which
+     * tls_get_record_header_len() does not count.
+     */
+    if (rl->cid_len != 0)
+        contenttypelen = 1 + rl->cid_len;
+
     /*
      * If we have a cipher in place then the tag is mandatory. If the cipher is
      * CBC mode then an explicit IV is also mandatory. If we know the digest,
