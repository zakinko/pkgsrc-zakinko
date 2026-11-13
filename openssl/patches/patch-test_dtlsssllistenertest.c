$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- test/dtlsssllistenertest.c.orig
+++ test/dtlsssllistenertest.c
@@ -8533,6 +8533,211 @@ end:
 }
 #endif /* OPENSSL_NO_DTLS1_3 */
 
+#ifndef OPENSSL_NO_DTLS1_2
+/*
+ * DTLS 1.2 Connection IDs on a listener (RFC 9146): routing by CID and the
+ * peer address change of section 6.
+ */
+#define LISTENER_CID_LEN 6
+
+static int peer_change_calls;
+static int peer_change_answer;
+static uint16_t peer_change_new_port;
+
+static int peer_change_cb(SSL *s, const BIO_ADDR *old_addr,
+    const BIO_ADDR *new_addr, void *arg)
+{
+    peer_change_calls++;
+    peer_change_new_port = ntohs(BIO_ADDR_rawport(new_addr));
+    return peer_change_answer;
+}
+
+static uint16_t conn_peer_port(SSL *ssl)
+{
+    SSL_CONNECTION *sc = SSL_CONNECTION_FROM_SSL_ONLY(ssl);
+
+    if (sc == NULL || sc->d1 == NULL)
+        return 0;
+    return ntohs(BIO_ADDR_rawport(&sc->d1->peer_addr));
+}
+
+/*
+ *   0: the client stays put
+ *   1: the client moves; no RRC, the callback says no, so the address stays
+ *   2: the client moves; no RRC, the callback says yes, so the address moves
+ *   3: the listener gives no CIDs; the extension is not negotiated
+ *   4: an application cannot replace the CID the listener chose
+ *   5: the client moves; the Return Routability Check (RFC 9853) succeeds
+ *      and the address moves, without asking the callback
+ *   6: the client moves; the check times out (section 5.1, "If T expires,
+ *      the peer address binding is not updated")
+ */
+static int test_dtls12_listener_cid(int idx)
+{
+    static const unsigned char ccid[] = { 0xc1, 0xc2 };
+    SSL_CTX *sctx = NULL, *cctx = NULL;
+    SSL *listener = NULL, *serverssl = NULL, *clientssl = NULL;
+    BIO_ADDR *client_addr = NULL, *moved = NULL;
+    const unsigned char *own, *peer;
+    size_t ownlen, peerlen, n;
+    struct in_addr ina;
+    char buf[64];
+    int abortctr = 0, testresult = 0;
+
+    peer_change_calls = 0;
+    peer_change_answer = idx == 2;
+    peer_change_new_port = 0;
+
+    if (!TEST_true(create_ssl_ctx_pair(NULL, DTLS_server_method(),
+            DTLS_client_method(), DTLS1_2_VERSION, DTLS1_2_VERSION,
+            &sctx, &cctx, cert, privkey)))
+        goto end;
+    SSL_CTX_set_dtls_peer_addr_change_cb(sctx, peer_change_cb, NULL);
+
+    if (!TEST_true(create_dtls_listener_and_client_mem(sctx, cctx,
+            SSL_LISTENER_FLAG_NO_VALIDATE | SSL_LISTENER_FLAG_SINGLE_THREAD,
+            &listener, &clientssl, &client_addr))
+        || (idx != 3
+            && !TEST_true(SSL_set_value_uint(listener, SSL_VALUE_CLASS_GENERIC,
+                SSL_VALUE_DTLS_LISTENER_CID_LEN, LISTENER_CID_LEN)))
+        || !TEST_true(SSL_set1_dtls_cid(clientssl, ccid, sizeof(ccid)))
+        || ((idx == 1 || idx == 2)
+            && !TEST_true(SSL_set_dtls_rrc(clientssl, 0))))
+        goto end;
+    timeout_test_fake_time = ossl_time_now();
+    if (!TEST_true(ossl_dtls_listener_set_override_now_cb(listener,
+            timeout_test_now_cb, NULL)))
+        goto end;
+
+    SSL_set_connect_state(clientssl);
+    while (serverssl == NULL) {
+        int ret, err;
+
+        if (!TEST_int_lt(++abortctr, 100))
+            goto end;
+        ret = SSL_connect(clientssl);
+        err = SSL_get_error(clientssl, ret);
+        if (ret <= 0 && err != SSL_ERROR_WANT_READ
+            && !TEST_int_eq(err, SSL_ERROR_WANT_WRITE))
+            goto end;
+        serverssl = SSL_accept_connection(listener,
+            SSL_ACCEPT_CONNECTION_NO_BLOCK);
+    }
+    if (!TEST_true(create_ssl_connection(serverssl, clientssl, SSL_ERROR_NONE)))
+        goto end;
+
+    if (idx == 3) {
+        testresult = TEST_int_eq(SSL_get0_dtls_cid(serverssl, NULL, NULL,
+                                     NULL, NULL),
+                         0)
+            && TEST_int_eq(SSL_get0_dtls_cid(clientssl, NULL, NULL, NULL, NULL),
+                0);
+        goto end;
+    }
+
+    /* The listener's CID is the one the client sends with */
+    if (!TEST_int_eq(SSL_get0_dtls_cid(serverssl, &own, &ownlen, &peer,
+                         &peerlen),
+            1)
+        || !TEST_size_t_eq(ownlen, LISTENER_CID_LEN)
+        || !TEST_mem_eq(peer, peerlen, ccid, sizeof(ccid))
+        || !TEST_int_eq(SSL_get0_dtls_cid(clientssl, NULL, NULL, &peer,
+                            &peerlen),
+            1)
+        || !TEST_mem_eq(peer, peerlen, own, ownlen))
+        goto end;
+
+    if (idx == 4) {
+        ERR_set_mark();
+        testresult = TEST_false(SSL_set1_dtls_cid(serverssl, ccid, sizeof(ccid)));
+        ERR_pop_to_mark();
+        goto end;
+    }
+
+    if (!TEST_int_eq(SSL_get_dtls_rrc(serverssl), idx != 1 && idx != 2)
+        || !TEST_int_eq(SSL_get_dtls_rrc(clientssl), idx != 1 && idx != 2))
+        goto end;
+
+    if (idx == 1 || idx == 2 || idx == 5 || idx == 6) {
+        /* A NAT rebinding: the client's datagrams now come from port 23456 */
+        ina.s_addr = htonl(INADDR_LOOPBACK);
+        if (!TEST_ptr(moved = BIO_ADDR_new())
+            || !TEST_true(BIO_ADDR_rawmake(moved, AF_INET, &ina, sizeof(ina),
+                htons(23456)))
+            || !TEST_int_eq(BIO_dgram_set0_local_addr(SSL_get_wbio(clientssl),
+                                moved),
+                1))
+            goto end;
+        moved = NULL;
+    }
+
+    if (!TEST_true(SSL_write_ex(clientssl, "moved", 5, &n))
+        || !TEST_true(dtls_read_with_retry(serverssl, buf, sizeof(buf), &n))
+        || !TEST_mem_eq(buf, n, "moved", 5))
+        goto end;
+
+    switch (idx) {
+    case 0:
+        if (!TEST_int_eq(peer_change_calls, 0)
+            || !TEST_int_eq(conn_peer_port(serverssl), 12345))
+            goto end;
+        break;
+    case 1:
+        if (!TEST_int_ge(peer_change_calls, 1)
+            || !TEST_int_eq(peer_change_new_port, 23456)
+            || !TEST_int_eq(conn_peer_port(serverssl), 12345))
+            goto end;
+        break;
+    case 2:
+        if (!TEST_int_eq(peer_change_calls, 1)
+            || !TEST_int_eq(conn_peer_port(serverssl), 23456))
+            goto end;
+        break;
+    case 5:
+    case 6:
+        /*
+         * The server has sent a path_challenge to the new address and still
+         * sends to the old one; the callback is not asked.
+         */
+        if (!TEST_int_eq(peer_change_calls, 0)
+            || !TEST_int_eq(conn_peer_port(serverssl), 12345)
+            || !TEST_true(SSL_get0_dtls_cid(serverssl, NULL, NULL, NULL, NULL))
+            || !TEST_true(SSL_get_dtls_rrc(serverssl)))
+            goto end;
+        if (idx == 6)
+            timeout_test_fake_time = ossl_time_add(timeout_test_fake_time,
+                ossl_ms2time(2000));
+        /* The client answers the challenge while waiting for data */
+        if (!TEST_false(SSL_read_ex(clientssl, buf, sizeof(buf), &n))
+            || !TEST_int_eq(SSL_get_error(clientssl, 0), SSL_ERROR_WANT_READ)
+            /* and the server takes the path_response */
+            || !TEST_false(SSL_read_ex(serverssl, buf, sizeof(buf), &n))
+            || !TEST_int_eq(SSL_get_error(serverssl, 0), SSL_ERROR_WANT_READ)
+            || !TEST_int_eq(conn_peer_port(serverssl), idx == 5 ? 23456 : 12345)
+            || !TEST_int_eq(peer_change_calls, 0))
+            goto end;
+        break;
+    }
+
+    /* And the other way */
+    if (!TEST_true(SSL_write_ex(serverssl, "reply", 5, &n))
+        || !TEST_true(dtls_read_with_retry(clientssl, buf, sizeof(buf), &n))
+        || !TEST_mem_eq(buf, n, "reply", 5))
+        goto end;
+
+    testresult = 1;
+end:
+    BIO_ADDR_free(moved);
+    BIO_ADDR_free(client_addr);
+    SSL_free(serverssl);
+    SSL_free(clientssl);
+    SSL_free(listener);
+    SSL_CTX_free(sctx);
+    SSL_CTX_free(cctx);
+    return testresult;
+}
+#endif /* OPENSSL_NO_DTLS1_2 */
+
 OPT_TEST_DECLARE_USAGE("certfile privkeyfile\n")
 
 int setup_tests(void)
@@ -8701,6 +8906,9 @@ int setup_tests(void)
 #endif
 #ifndef OPENSSL_NO_DTLS1_2
     ADD_TEST(test_dtls12_listener_alert_after_hvr_frees_pending);
+#ifndef OPENSSL_NO_DTLS1_2
+    ADD_ALL_TESTS(test_dtls12_listener_cid, 7);
+#endif
 #endif
 
     return 1;
