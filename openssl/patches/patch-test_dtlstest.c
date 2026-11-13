$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- test/dtlstest.c.orig
+++ test/dtlstest.c
@@ -2577,6 +2577,643 @@ end:
 }
 #endif /* OPENSSL_NO_DTLS1_3 */
 
+#ifndef OPENSSL_NO_DTLS1_2
+/*
+ * DTLS 1.2 Connection ID, RFC 9146.
+ */
+
+/* The header of the last record each side sent, captured by cid_msg_cb() */
+typedef struct {
+    unsigned char hdr[DTLS1_RT_HEADER_LENGTH + SSL_DTLS_CID_MAX_LEN];
+    size_t hdrlen;
+} CID_LAST_HDR;
+
+static void cid_msg_cb(int write_p, int version, int content_type,
+    const void *buf, size_t len, SSL *ssl, void *arg)
+{
+    CID_LAST_HDR *last = arg;
+
+    if (!write_p || content_type != SSL3_RT_HEADER
+        || len > sizeof(last->hdr))
+        return;
+    memcpy(last->hdr, buf, len);
+    last->hdrlen = len;
+}
+
+static const char *cid_ciphers[] = {
+    "ECDHE-RSA-AES128-GCM-SHA256", /* RFC 5288 nonce */
+    "DHE-RSA-AES128-CCM", /* RFC 6655 nonce */
+    /* RFC 6655 nonce, 8 byte tag, below the default security level */
+    "DHE-RSA-AES128-CCM8:@SECLEVEL=0",
+    "ECDHE-RSA-CHACHA20-POLY1305", /* RFC 7905 nonce */
+    "ECDHE-RSA-AES128-SHA256", /* CBC, Encrypt-then-MAC: RFC 9146 5.2 */
+};
+
+static const unsigned char cid_client[] = { 0xc1, 0xc2, 0xc3, 0xc4 };
+static const unsigned char cid_server[] = {
+    0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58
+};
+
+/*
+ * Set up a DTLS 1.2 connection using |cipher| with each side asking for a
+ * CID of |clen| and |slen| bytes (0: empty CID, -1: extension not enabled).
+ */
+static int cid_connect(const char *cipher, int clen, int slen,
+    SSL_CTX **sctx, SSL_CTX **cctx, SSL **sssl, SSL **cssl,
+    CID_LAST_HDR *clast, CID_LAST_HDR *slast, int *skip)
+{
+    *skip = 0;
+    if (!TEST_true(create_ssl_ctx_pair(NULL, DTLS_server_method(),
+            DTLS_client_method(), DTLS1_VERSION, DTLS1_2_VERSION,
+            sctx, cctx, cert, privkey))
+        || !TEST_true(SSL_CTX_set_dh_auto(*sctx, 1)))
+        return 0;
+    if (!SSL_CTX_set_cipher_list(*cctx, cipher)) {
+        *skip = 1;
+        return 0;
+    }
+    if (!TEST_true(SSL_CTX_set_cipher_list(*sctx, cipher))
+        || !TEST_true(create_ssl_objects(*sctx, *cctx, sssl, cssl,
+            NULL, NULL))
+        || (clen >= 0
+            && !TEST_true(SSL_set1_dtls_cid(*cssl, cid_client, (size_t)clen)))
+        || (slen >= 0
+            && !TEST_true(SSL_set1_dtls_cid(*sssl, cid_server, (size_t)slen))))
+        return 0;
+
+    /* The client writes records carrying the server's CID and vice versa */
+    BIO_ctrl(SSL_get_wbio(*cssl), MEMPACKET_CTRL_SET_CID_LEN,
+        slen > 0 ? slen : 0, NULL);
+    BIO_ctrl(SSL_get_wbio(*sssl), MEMPACKET_CTRL_SET_CID_LEN,
+        clen > 0 ? clen : 0, NULL);
+
+    /* A record layer takes the callback when it is made, so set it first */
+    if (clast != NULL) {
+        SSL_set_msg_callback(*cssl, cid_msg_cb);
+        SSL_set_msg_callback_arg(*cssl, clast);
+    }
+    if (slast != NULL) {
+        SSL_set_msg_callback(*sssl, cid_msg_cb);
+        SSL_set_msg_callback_arg(*sssl, slast);
+    }
+
+    return TEST_true(create_ssl_connection(*sssl, *cssl, SSL_ERROR_NONE));
+}
+
+/*
+ * Send |msg| from |from| to |to| and check the outer record header |from|
+ * wrote: tls12_cid with |cid| after the sequence number (RFC 9146 section 4,
+ * Figure 3) when |cidlen| is not zero, application_data otherwise.
+ */
+static int cid_send(SSL *from, SSL *to, const unsigned char *cid,
+    size_t cidlen, CID_LAST_HDR *last)
+{
+    static const char msg[] = "connection id";
+    char buf[sizeof(msg)];
+    size_t n;
+
+    last->hdrlen = 0;
+    if (!TEST_true(SSL_write_ex(from, msg, sizeof(msg), &n))
+        || !TEST_size_t_eq(n, sizeof(msg))
+        || !TEST_true(SSL_read_ex(to, buf, sizeof(buf), &n))
+        || !TEST_mem_eq(buf, n, msg, sizeof(msg)))
+        return 0;
+
+    if (cidlen == 0)
+        return TEST_size_t_eq(last->hdrlen, DTLS1_RT_HEADER_LENGTH)
+            && TEST_int_eq(last->hdr[0], SSL3_RT_APPLICATION_DATA);
+
+    return TEST_size_t_eq(last->hdrlen, DTLS1_RT_HEADER_LENGTH + cidlen)
+        && TEST_int_eq(last->hdr[0], SSL3_RT_TLS12_CID)
+        && TEST_mem_eq(last->hdr + 11, cidlen, cid, cidlen);
+}
+
+/* A CID as SSL_get0_dtls_cid() returns it: a zero length one may be NULL */
+static int cid_eq(const unsigned char *got, size_t gotlen,
+    const unsigned char *want, size_t wantlen)
+{
+    if (!TEST_size_t_eq(gotlen, wantlen))
+        return 0;
+    return wantlen == 0 || TEST_mem_eq(got, gotlen, want, wantlen);
+}
+
+/*
+ * Each cipher of cid_ciphers[] with CIDs in both directions, only towards the
+ * server (the client offers an empty CID) and only towards the client.
+ */
+static int test_dtls_cid(int idx)
+{
+    static const int lens[3][2] = {
+        { sizeof(cid_client), sizeof(cid_server) },
+        { 0, sizeof(cid_server) },
+        { sizeof(cid_client), 0 },
+    };
+    const char *cipher = cid_ciphers[idx / 3];
+    int clen = lens[idx % 3][0], slen = lens[idx % 3][1];
+    SSL_CTX *sctx = NULL, *cctx = NULL;
+    SSL *sssl = NULL, *cssl = NULL;
+    CID_LAST_HDR clast, slast;
+    const unsigned char *own, *peer;
+    size_t ownlen, peerlen;
+    int skip, testresult = 0;
+
+    if (!cid_connect(cipher, clen, slen, &sctx, &cctx, &sssl, &cssl,
+            &clast, &slast, &skip)) {
+        if (skip)
+            testresult = TEST_skip("%s not available", cipher);
+        goto end;
+    }
+
+    /* Each side receives the CID it asked for and sends the other's */
+    if (!TEST_int_eq(SSL_get0_dtls_cid(cssl, &own, &ownlen, &peer, &peerlen), 1)
+        || !cid_eq(own, ownlen, cid_client, (size_t)clen)
+        || !cid_eq(peer, peerlen, cid_server, (size_t)slen)
+        || !TEST_int_eq(SSL_get0_dtls_cid(sssl, &own, &ownlen, &peer, &peerlen), 1)
+        || !cid_eq(own, ownlen, cid_server, (size_t)slen)
+        || !cid_eq(peer, peerlen, cid_client, (size_t)clen))
+        goto end;
+
+    if (!cid_send(cssl, sssl, cid_server, (size_t)slen, &clast)
+        || !cid_send(sssl, cssl, cid_client, (size_t)clen, &slast)
+        || !cid_send(cssl, sssl, cid_server, (size_t)slen, &clast))
+        goto end;
+
+    testresult = 1;
+end:
+    SSL_free(sssl);
+    SSL_free(cssl);
+    SSL_CTX_free(sctx);
+    SSL_CTX_free(cctx);
+    return testresult;
+}
+
+/*
+ * Connections where the extension is not negotiated go ahead without CIDs.
+ *   0: both sides enable it, but the client turns Encrypt-then-MAC off, so
+ *      RFC 9146 section 5.1 (MAC-then-encrypt) would apply, which is not
+ *      implemented, and the server declines
+ *   1: only the client enables it; the server ignores it
+ *   2: only the server enables it; the client does not offer it
+ */
+static int test_dtls_cid_declined(int idx)
+{
+    SSL_CTX *sctx = NULL, *cctx = NULL;
+    SSL *sssl = NULL, *cssl = NULL;
+    CID_LAST_HDR clast;
+    int testresult = 0;
+
+    if (!TEST_true(create_ssl_ctx_pair(NULL, DTLS_server_method(),
+            DTLS_client_method(), DTLS1_VERSION, DTLS1_2_VERSION,
+            &sctx, &cctx, cert, privkey))
+        || !TEST_true(SSL_CTX_set_cipher_list(cctx, "ECDHE-RSA-AES128-SHA256"))
+        || !TEST_true(SSL_CTX_set_cipher_list(sctx, "ECDHE-RSA-AES128-SHA256")))
+        goto end;
+    if (idx == 0)
+        SSL_CTX_set_options(cctx, SSL_OP_NO_ENCRYPT_THEN_MAC);
+    if (!TEST_true(create_ssl_objects(sctx, cctx, &sssl, &cssl, NULL, NULL))
+        || (idx != 2
+            && !TEST_true(SSL_set1_dtls_cid(cssl, cid_client, sizeof(cid_client))))
+        || (idx != 1
+            && !TEST_true(SSL_set1_dtls_cid(sssl, cid_server, sizeof(cid_server)))))
+        goto end;
+    SSL_set_msg_callback(cssl, cid_msg_cb);
+    SSL_set_msg_callback_arg(cssl, &clast);
+    if (!TEST_true(create_ssl_connection(sssl, cssl, SSL_ERROR_NONE))
+        || !TEST_int_eq(SSL_get0_dtls_cid(cssl, NULL, NULL, NULL, NULL), 0)
+        || !TEST_int_eq(SSL_get0_dtls_cid(sssl, NULL, NULL, NULL, NULL), 0))
+        goto end;
+
+    if (!cid_send(cssl, sssl, NULL, 0, &clast))
+        goto end;
+
+    testresult = 1;
+end:
+    SSL_free(sssl);
+    SSL_free(cssl);
+    SSL_CTX_free(sctx);
+    SSL_CTX_free(cctx);
+    return testresult;
+}
+
+/*
+ * Invalid tls12_cid records are discarded silently (RFC 9146 section 6, RFC
+ * 6347 section 4.1.2.7) and the connection carries on.
+ *   0: a CID other than ours
+ *   1: a record without a CID where one is expected (RFC 9146 section 3)
+ *   2: a datagram ending inside the CID, right after the sequence number
+ *   3: a tampered ciphertext (bad MAC, RFC 9146 section 6)
+ *   4: a tampered CID that the record's MAC covers (RFC 9146 section 5)
+ */
+static int test_dtls_cid_discard(int idx)
+{
+    SSL_CTX *sctx = NULL, *cctx = NULL;
+    SSL *sssl = NULL, *cssl = NULL;
+    BIO *c2s;
+    unsigned char pkt[512], bad[512];
+    char buf[16];
+    int pktlen, badlen, skip, testresult = 0;
+    size_t n, hdr = DTLS1_RT_HEADER_LENGTH + sizeof(cid_server);
+
+    if (!cid_connect(cid_ciphers[0], sizeof(cid_client), sizeof(cid_server),
+            &sctx, &cctx, &sssl, &cssl, NULL, NULL, &skip)) {
+        if (skip)
+            testresult = TEST_skip("%s not available", cid_ciphers[0]);
+        goto end;
+    }
+
+    /* Take the client's next datagram off the wire */
+    c2s = SSL_get_wbio(cssl);
+    if (!TEST_true(SSL_write_ex(cssl, "x", 1, &n))
+        || !TEST_int_gt(pktlen = BIO_read(c2s, pkt, sizeof(pkt)), 0)
+        || !TEST_int_eq(pkt[0], SSL3_RT_TLS12_CID)
+        || !TEST_size_t_gt((size_t)pktlen, hdr))
+        goto end;
+
+    memcpy(bad, pkt, (size_t)pktlen);
+    badlen = pktlen;
+    switch (idx) {
+    case 0:
+    case 4:
+        bad[11] ^= 0x01;
+        break;
+    case 1:
+        /* The same record in the RFC 6347 format, CID taken out */
+        bad[0] = SSL3_RT_APPLICATION_DATA;
+        memmove(bad + 11, bad + 11 + sizeof(cid_server),
+            (size_t)pktlen - 11 - sizeof(cid_server));
+        badlen = pktlen - (int)sizeof(cid_server);
+        break;
+    case 2:
+        /*
+         * The test BIO frames this as an RFC 6347 record with a zero
+         * length; the server sees tls12_cid and no room for the CID.
+         */
+        bad[11] = bad[12] = 0;
+        badlen = DTLS1_RT_HEADER_LENGTH;
+        break;
+    case 3:
+        bad[pktlen - 1] ^= 0x01;
+        break;
+    }
+
+    /* The BIO frames injected datagrams itself; give it whole ones only */
+    BIO_ctrl(c2s, MEMPACKET_CTRL_SET_CID_LEN, idx == 2 ? 0 : sizeof(cid_server),
+        NULL);
+    if (idx == 4) {
+        /*
+         * Make the server expect the tampered CID, so that the record gets
+         * past the lookup and fails on the MAC, which covers the CID.
+         */
+        OSSL_RECORD_LAYER *rl = SSL_CONNECTION_FROM_SSL_ONLY(sssl)->rlayer.rrl;
+
+        if (!TEST_ptr(rl) || !TEST_size_t_eq(rl->cid_len, sizeof(cid_server)))
+            goto end;
+        rl->cid[0] ^= 0x01;
+    }
+    if (!TEST_int_eq(mempacket_test_inject(c2s, (char *)bad, badlen, -1,
+                         INJECT_PACKET_IGNORE_REC_SEQ),
+            badlen)
+        || !TEST_false(SSL_read_ex(sssl, buf, sizeof(buf), &n))
+        || !TEST_int_eq(SSL_get_error(sssl, 0), SSL_ERROR_WANT_READ))
+        goto end;
+    if (idx == 4)
+        SSL_CONNECTION_FROM_SSL_ONLY(sssl)->rlayer.rrl->cid[0] ^= 0x01;
+
+    /* The genuine record still gets through */
+    BIO_ctrl(c2s, MEMPACKET_CTRL_SET_CID_LEN, sizeof(cid_server), NULL);
+    if (!TEST_int_eq(mempacket_test_inject(c2s, (char *)pkt, pktlen, -1,
+                         INJECT_PACKET_IGNORE_REC_SEQ),
+            pktlen)
+        || !TEST_true(SSL_read_ex(sssl, buf, sizeof(buf), &n))
+        || !TEST_mem_eq(buf, n, "x", 1))
+        goto end;
+
+    testresult = 1;
+end:
+    SSL_free(sssl);
+    SSL_free(cssl);
+    SSL_CTX_free(sctx);
+    SSL_CTX_free(cctx);
+    return testresult;
+}
+
+/*
+ * RFC 9146 section 5: length_of_DTLSInnerPlaintext "MUST NOT exceed 2^14", so
+ * a record with a CID carries at most 2^14 - 1 bytes.  idx 0: with CIDs,
+ * idx 1: without, where 2^14 bytes still go in one record.
+ */
+static int test_dtls_cid_max_fragment(int idx)
+{
+    SSL_CTX *sctx = NULL, *cctx = NULL;
+    SSL *sssl = NULL, *cssl = NULL;
+    unsigned char *out = NULL, *in = NULL;
+    size_t max = idx == 0 ? SSL3_RT_MAX_PLAIN_LENGTH - 1 : SSL3_RT_MAX_PLAIN_LENGTH;
+    size_t n;
+    int skip, testresult = 0;
+
+    if (!TEST_ptr(out = OPENSSL_zalloc(SSL3_RT_MAX_PLAIN_LENGTH + 1))
+        || !TEST_ptr(in = OPENSSL_zalloc(SSL3_RT_MAX_PLAIN_LENGTH + 1)))
+        goto end;
+    memset(out, 'a', SSL3_RT_MAX_PLAIN_LENGTH + 1);
+    if (!cid_connect(cid_ciphers[0], idx == 0 ? (int)sizeof(cid_client) : -1,
+            idx == 0 ? (int)sizeof(cid_server) : -1,
+            &sctx, &cctx, &sssl, &cssl, NULL, NULL, &skip)) {
+        if (skip)
+            testresult = TEST_skip("%s not available", cid_ciphers[0]);
+        goto end;
+    }
+
+    if (!TEST_true(SSL_write_ex(cssl, out, max, &n))
+        || !TEST_size_t_eq(n, max)
+        || !TEST_true(SSL_read_ex(sssl, in, SSL3_RT_MAX_PLAIN_LENGTH + 1, &n))
+        || !TEST_mem_eq(in, n, out, max))
+        goto end;
+    ERR_set_mark();
+    if (!TEST_false(SSL_write_ex(cssl, out, max + 1, &n))) {
+        ERR_clear_last_mark();
+        goto end;
+    }
+    ERR_pop_to_mark();
+
+    testresult = 1;
+end:
+    OPENSSL_free(out);
+    OPENSSL_free(in);
+    SSL_free(sssl);
+    SSL_free(cssl);
+    SSL_CTX_free(sctx);
+    SSL_CTX_free(cctx);
+    return testresult;
+}
+
+#ifndef OPENSSL_NO_DTLS1_3
+/*
+ * DTLS 1.3 with CIDs (RFC 9147 sections 4 and 9.1), in both directions and
+ * in one: the unified header carries the C bit and the CID right after its
+ * first byte, from the handshake epoch on.  idx / 3 picks the cipher suite.
+ */
+static int test_dtls13_cid(int idx)
+{
+    static const char *suites[] = {
+        "TLS_AES_128_GCM_SHA256",
+        "TLS_CHACHA20_POLY1305_SHA256",
+    };
+    static const int lens[3][2] = {
+        { sizeof(cid_client), sizeof(cid_server) },
+        { 0, sizeof(cid_server) },
+        { sizeof(cid_client), 0 },
+    };
+    static const char msg[] = "dtls 1.3 connection id";
+    int clen = lens[idx % 3][0], slen = lens[idx % 3][1];
+    SSL_CTX *sctx = NULL, *cctx = NULL;
+    SSL *sssl = NULL, *cssl = NULL;
+    CID_LAST_HDR clast, slast;
+    const unsigned char *own, *peer;
+    size_t ownlen, peerlen, n;
+    char buf[sizeof(msg)];
+    int testresult = 0;
+
+    if (!TEST_true(create_ssl_ctx_pair(NULL, DTLS_server_method(),
+            DTLS_client_method(), DTLS1_3_VERSION, DTLS1_3_VERSION,
+            &sctx, &cctx, cert, privkey)))
+        goto end;
+    if (!SSL_CTX_set_ciphersuites(cctx, suites[idx / 3])) {
+        testresult = TEST_skip("%s not available", suites[idx / 3]);
+        goto end;
+    }
+    if (!TEST_true(SSL_CTX_set_ciphersuites(sctx, suites[idx / 3]))
+        || !TEST_true(create_ssl_objects(sctx, cctx, &sssl, &cssl, NULL, NULL))
+        || !TEST_true(SSL_set1_dtls_cid(cssl, cid_client, (size_t)clen))
+        || !TEST_true(SSL_set1_dtls_cid(sssl, cid_server, (size_t)slen)))
+        goto end;
+    BIO_ctrl(SSL_get_wbio(cssl), MEMPACKET_CTRL_SET_CID_LEN, slen, NULL);
+    BIO_ctrl(SSL_get_wbio(sssl), MEMPACKET_CTRL_SET_CID_LEN, clen, NULL);
+    SSL_set_msg_callback(cssl, cid_msg_cb);
+    SSL_set_msg_callback_arg(cssl, &clast);
+    SSL_set_msg_callback(sssl, cid_msg_cb);
+    SSL_set_msg_callback_arg(sssl, &slast);
+
+    if (!TEST_true(create_ssl_connection(sssl, cssl, SSL_ERROR_NONE))
+        || !TEST_int_eq(SSL_version(cssl), DTLS1_3_VERSION)
+        || !TEST_int_eq(SSL_get0_dtls_cid(cssl, &own, &ownlen, &peer, &peerlen), 1)
+        || !cid_eq(own, ownlen, cid_client, (size_t)clen)
+        || !cid_eq(peer, peerlen, cid_server, (size_t)slen)
+        || !TEST_int_eq(SSL_get0_dtls_cid(sssl, &own, &ownlen, &peer, &peerlen), 1)
+        || !cid_eq(own, ownlen, cid_server, (size_t)slen)
+        || !cid_eq(peer, peerlen, cid_client, (size_t)clen))
+        goto end;
+
+    /* Client to server: the server's CID after the first byte */
+    clast.hdrlen = 0;
+    if (!TEST_true(SSL_write_ex(cssl, msg, sizeof(msg), &n))
+        || !TEST_true(SSL_read_ex(sssl, buf, sizeof(buf), &n))
+        || !TEST_mem_eq(buf, n, msg, sizeof(msg))
+        || !TEST_size_t_gt(clast.hdrlen, 0)
+        || !TEST_int_eq(clast.hdr[0] & DTLS13_UNI_HDR_FIX_BITS_MASK,
+            DTLS13_UNI_HDR_FIX_BITS)
+        || !TEST_int_eq((clast.hdr[0] & DTLS13_UNI_HDR_CID_BIT) != 0, slen != 0)
+        || (slen != 0
+            && !TEST_mem_eq(clast.hdr + 1, (size_t)slen, cid_server,
+                (size_t)slen)))
+        goto end;
+
+    /* Server to client: the client's CID */
+    slast.hdrlen = 0;
+    if (!TEST_true(SSL_write_ex(sssl, msg, sizeof(msg), &n))
+        || !TEST_true(SSL_read_ex(cssl, buf, sizeof(buf), &n))
+        || !TEST_mem_eq(buf, n, msg, sizeof(msg))
+        || !TEST_size_t_gt(slast.hdrlen, 0)
+        || !TEST_int_eq((slast.hdr[0] & DTLS13_UNI_HDR_CID_BIT) != 0, clen != 0)
+        || (clen != 0
+            && !TEST_mem_eq(slast.hdr + 1, (size_t)clen, cid_client,
+                (size_t)clen)))
+        goto end;
+
+    testresult = 1;
+end:
+    SSL_free(sssl);
+    SSL_free(cssl);
+    SSL_CTX_free(sctx);
+    SSL_CTX_free(cctx);
+    return testresult;
+}
+#endif
+
+#ifndef OPENSSL_NO_DTLS1_3
+/* Send |msg| from |from| to |to|; post-handshake messages travel with it */
+static int cid_pass(SSL *from, SSL *to, const char *msg)
+{
+    char buf[64];
+    size_t n, len = strlen(msg);
+
+    return TEST_true(SSL_write_ex(from, msg, len, &n))
+        && TEST_true(SSL_read_ex(to, buf, sizeof(buf), &n))
+        && TEST_mem_eq(buf, n, msg, len);
+}
+
+/*
+ * Run both ends until neither is in a handshake: a DTLS 1.3 post-handshake
+ * message waits for its ACK (RFC 9147 section 7) before the sender writes
+ * again, and the answer to RequestConnectionId is a flight of its own.
+ */
+static int cid_settle(SSL *a, SSL *b)
+{
+    char buf[64];
+    size_t n;
+    int i;
+
+    for (i = 0; i < 8; i++) {
+        if (!SSL_in_init(a) && !SSL_in_init(b))
+            return 1;
+        if (SSL_read_ex(a, buf, sizeof(buf), &n)
+            || SSL_get_error(a, 0) != SSL_ERROR_WANT_READ
+            || SSL_read_ex(b, buf, sizeof(buf), &n)
+            || SSL_get_error(b, 0) != SSL_ERROR_WANT_READ)
+            break;
+    }
+    TEST_error("unexpected data, error, or still in a handshake");
+    return 0;
+}
+
+/*
+ * RFC 9147 section 9, CID updates over a DTLS 1.3 connection with CIDs both
+ * ways.
+ *   0: the client gives a new CID for immediate use (NewConnectionId,
+ *      cid_immediate); the server's records carry it from then on
+ *   1: the server asks for two spare CIDs (RequestConnectionId); the client
+ *      answers with a NewConnectionId, cid_spare, carrying two
+ *   2: neither message can be asked for on a DTLS 1.2 connection
+ */
+static int test_dtls13_cid_update(int idx)
+{
+    SSL_CTX *sctx = NULL, *cctx = NULL;
+    SSL *sssl = NULL, *cssl = NULL;
+    SSL_CONNECTION *ssc, *csc;
+    CID_LAST_HDR clast, slast;
+    const unsigned char *peer;
+    size_t peerlen;
+    int testresult = 0;
+
+    if (!TEST_true(create_ssl_ctx_pair(NULL, DTLS_server_method(),
+            DTLS_client_method(), idx == 2 ? DTLS1_2_VERSION : DTLS1_3_VERSION,
+            idx == 2 ? DTLS1_2_VERSION : DTLS1_3_VERSION,
+            &sctx, &cctx, cert, privkey))
+        || !TEST_true(create_ssl_objects(sctx, cctx, &sssl, &cssl, NULL, NULL)))
+        goto end;
+    if (idx != 2) {
+        if (!TEST_true(SSL_set1_dtls_cid(cssl, cid_client, sizeof(cid_client)))
+            || !TEST_true(SSL_set1_dtls_cid(sssl, cid_server, sizeof(cid_server))))
+            goto end;
+        BIO_ctrl(SSL_get_wbio(cssl), MEMPACKET_CTRL_SET_CID_LEN,
+            sizeof(cid_server), NULL);
+        BIO_ctrl(SSL_get_wbio(sssl), MEMPACKET_CTRL_SET_CID_LEN,
+            sizeof(cid_client), NULL);
+    }
+    SSL_set_msg_callback(cssl, cid_msg_cb);
+    SSL_set_msg_callback_arg(cssl, &clast);
+    SSL_set_msg_callback(sssl, cid_msg_cb);
+    SSL_set_msg_callback_arg(sssl, &slast);
+    if (!TEST_true(create_ssl_connection(sssl, cssl, SSL_ERROR_NONE))
+        || !TEST_ptr(ssc = SSL_CONNECTION_FROM_SSL_ONLY(sssl))
+        || !TEST_ptr(csc = SSL_CONNECTION_FROM_SSL_ONLY(cssl)))
+        goto end;
+
+    switch (idx) {
+    case 0:
+        if (!TEST_true(SSL_dtls_new_connection_id(cssl, SSL_DTLS_CID_IMMEDIATE))
+            /* A second one waits for the first to be acknowledged */
+            || !TEST_false(SSL_dtls_new_connection_id(cssl, SSL_DTLS_CID_SPARE))
+            || !cid_settle(cssl, sssl)
+            || !TEST_int_eq(SSL_get0_dtls_cid(sssl, NULL, NULL, &peer, &peerlen), 1)
+            || !TEST_size_t_eq(peerlen, sizeof(cid_client))
+            || !TEST_mem_ne(peer, peerlen, cid_client, sizeof(cid_client))
+            || !TEST_size_t_eq(csc->ext.dtls_cid.own_more_num, 1)
+            || !TEST_mem_eq(peer, peerlen, csc->ext.dtls_cid.own_more,
+                sizeof(cid_client)))
+            goto end;
+        /* The server writes with the new CID, and the client takes it */
+        slast.hdrlen = 0;
+        if (!cid_pass(sssl, cssl, "with the new cid")
+            || !TEST_size_t_gt(slast.hdrlen, sizeof(cid_client))
+            || !TEST_mem_eq(slast.hdr + 1, sizeof(cid_client), peer, peerlen)
+            || !cid_pass(cssl, sssl, "still fine"))
+            goto end;
+        break;
+    case 1:
+        if (!TEST_true(SSL_dtls_request_connection_id(sssl, 2))
+            || !cid_settle(sssl, cssl)
+            /* Answered, so another may be made */
+            || !TEST_false(ssc->ext.dtls_cid.rcid_unfulfilled)
+            || !TEST_size_t_eq(ssc->ext.dtls_cid.spares_num, 2)
+            || !TEST_size_t_eq(csc->ext.dtls_cid.own_more_num, 2)
+            || !TEST_mem_eq(ssc->ext.dtls_cid.spares[0].cid,
+                ssc->ext.dtls_cid.spares[0].len, csc->ext.dtls_cid.own_more,
+                sizeof(cid_client))
+            /* The CID in use stays */
+            || !TEST_int_eq(SSL_get0_dtls_cid(sssl, NULL, NULL, &peer, &peerlen), 1)
+            || !TEST_mem_eq(peer, peerlen, cid_client, sizeof(cid_client)))
+            goto end;
+        break;
+    case 2:
+        ERR_set_mark();
+        if (!TEST_false(SSL_dtls_new_connection_id(cssl, SSL_DTLS_CID_IMMEDIATE))
+            || !TEST_false(SSL_dtls_request_connection_id(sssl, 1))) {
+            ERR_clear_last_mark();
+            goto end;
+        }
+        ERR_pop_to_mark();
+        break;
+    }
+
+    testresult = 1;
+end:
+    SSL_free(sssl);
+    SSL_free(cssl);
+    SSL_CTX_free(sctx);
+    SSL_CTX_free(cctx);
+    return testresult;
+}
+#endif
+
+static int test_dtls_cid_api(void)
+{
+    SSL_CTX *ctx = NULL, *tlsctx = NULL;
+    SSL *s = NULL, *tls = NULL;
+    unsigned char big[SSL_DTLS_CID_MAX_LEN + 1] = { 0 };
+    int testresult = 0;
+
+    if (!TEST_ptr(ctx = SSL_CTX_new(DTLS_client_method()))
+        || !TEST_ptr(s = SSL_new(ctx))
+        || !TEST_ptr(tlsctx = SSL_CTX_new(TLS_client_method()))
+        || !TEST_ptr(tls = SSL_new(tlsctx)))
+        goto end;
+
+    ERR_set_mark();
+    if (!TEST_false(SSL_set1_dtls_cid(tls, big, 1))
+        /* RFC 9146 section 3: opaque cid<0..2^8-1> */
+        || !TEST_false(SSL_set1_dtls_cid(s, big, sizeof(big)))
+        || !TEST_false(SSL_set1_dtls_cid(s, NULL, 1))) {
+        ERR_clear_last_mark();
+        goto end;
+    }
+    ERR_pop_to_mark();
+
+    if (!TEST_true(SSL_set1_dtls_cid(s, big, SSL_DTLS_CID_MAX_LEN))
+        || !TEST_true(SSL_set1_dtls_cid(s, NULL, 0))
+        || !TEST_int_eq(SSL_get0_dtls_cid(s, NULL, NULL, NULL, NULL), 0))
+        goto end;
+    SSL_clear_dtls_cid(s);
+
+    testresult = 1;
+end:
+    SSL_free(s);
+    SSL_free(tls);
+    SSL_CTX_free(ctx);
+    SSL_CTX_free(tlsctx);
+    return testresult;
+}
+#endif /* OPENSSL_NO_DTLS1_2 */
+
 OPT_TEST_DECLARE_USAGE("certfile privkeyfile\n")
 
 int setup_tests(void)
@@ -2634,6 +3271,17 @@ int setup_tests(void)
     && !defined(OPENSSL_NO_DTLS1_3)
     ADD_TEST(test_dtls_client_retransmit_dtls13);
     ADD_TEST(test_dtls_server_retransmit_dtls13);
+#endif
+#ifndef OPENSSL_NO_DTLS1_2
+    ADD_ALL_TESTS(test_dtls_cid, OSSL_NELEM(cid_ciphers) * 3);
+    ADD_ALL_TESTS(test_dtls_cid_declined, 3);
+    ADD_ALL_TESTS(test_dtls_cid_discard, 5);
+    ADD_ALL_TESTS(test_dtls_cid_max_fragment, 2);
+    ADD_TEST(test_dtls_cid_api);
+#ifndef OPENSSL_NO_DTLS1_3
+    ADD_ALL_TESTS(test_dtls13_cid, 6);
+    ADD_ALL_TESTS(test_dtls13_cid_update, 3);
+#endif
 #endif
 
     return 1;
