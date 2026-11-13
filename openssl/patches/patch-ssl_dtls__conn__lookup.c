$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/dtls_conn_lookup.c.orig
+++ ssl/dtls_conn_lookup.c
@@ -527,4 +527,137 @@ size_t ossl_dgram_conn_lookup_num_items(const DGRAM_CONN_LOOKUP *lookup)
     return lookup->methods->num_items(lookup);
 }
 
+/*
+ * Connection ID lookup.  The entries are DGRAM_CONN_ENTRY with the CID as the
+ * hash key and no peer address, so the SipHash keyed hash and the comparison
+ * above serve unchanged.
+ */
+struct dgram_cid_lookup_st {
+    LHASH_OF(DGRAM_CONN_ENTRY) *htable;
+    uint64_t hash_key[2]; /* 128-bit SipHash key */
+};
+
+DGRAM_CID_LOOKUP *ossl_dgram_cid_lookup_new(void)
+{
+    DGRAM_CID_LOOKUP *lookup = OPENSSL_zalloc(sizeof(*lookup));
+
+    if (lookup == NULL)
+        return NULL;
+
+    /* Random SipHash key: CIDs arrive from the network (hash flooding) */
+    if (RAND_priv_bytes((unsigned char *)lookup->hash_key,
+            sizeof(lookup->hash_key))
+            <= 0
+        || (lookup->htable = lh_DGRAM_CONN_ENTRY_new(conn_entry_hash,
+                conn_entry_cmp))
+            == NULL) {
+        OPENSSL_free(lookup);
+        return NULL;
+    }
+
+    return lookup;
+}
+
+SSL *ossl_dgram_cid_lookup_find(DGRAM_CID_LOOKUP *lookup,
+    const unsigned char *cid, size_t cid_len)
+{
+    DGRAM_CONN_ENTRY key, *result;
+
+    if (lookup == NULL || cid == NULL || cid_len == 0)
+        return NULL;
+
+    memset(&key, 0, sizeof(key));
+    key.hashkey = (uint8_t *)cid;
+    key.hashkey_len = cid_len;
+    key.siphash_key = lookup->hash_key;
+
+    result = lh_DGRAM_CONN_ENTRY_retrieve(lookup->htable, &key);
+    return result == NULL ? NULL : result->ssl;
+}
+
+int ossl_dgram_cid_lookup_register(DGRAM_CID_LOOKUP *lookup,
+    const unsigned char *cid, size_t cid_len, SSL *ssl)
+{
+    DGRAM_CONN_ENTRY *entry, *old;
+
+    if (lookup == NULL || cid == NULL || cid_len == 0 || ssl == NULL
+        || ossl_dgram_cid_lookup_find(lookup, cid, cid_len) != NULL)
+        return 0;
+
+    if ((entry = OPENSSL_zalloc(sizeof(*entry))) == NULL)
+        return 0;
+    entry->ssl = ssl;
+    entry->siphash_key = lookup->hash_key;
+    entry->hashkey_len = cid_len;
+    if ((entry->hashkey = OPENSSL_memdup(cid, cid_len)) == NULL) {
+        OPENSSL_free(entry);
+        return 0;
+    }
+
+    old = lh_DGRAM_CONN_ENTRY_insert(lookup->htable, entry);
+    if (lh_DGRAM_CONN_ENTRY_error(lookup->htable)) {
+        conn_entry_free(entry);
+        return 0;
+    }
+    /* The find above makes a replacement impossible */
+    if (!ossl_assert(old == NULL))
+        conn_entry_free(old);
+
+    return 1;
+}
+
+typedef struct {
+    SSL *ssl;
+    DGRAM_CONN_ENTRY *found;
+} CID_FIND_SSL_CTX;
+
+static void cid_find_ssl_cb(DGRAM_CONN_ENTRY *e, void *arg)
+{
+    CID_FIND_SSL_CTX *ctx = arg;
+
+    if (ctx->found == NULL && e->ssl == ctx->ssl)
+        ctx->found = e;
+}
+
+void ossl_dgram_cid_lookup_unregister_ssl(DGRAM_CID_LOOKUP *lookup, SSL *ssl)
+{
+    CID_FIND_SSL_CTX ctx;
+    DGRAM_CONN_ENTRY *removed;
+
+    if (lookup == NULL || ssl == NULL)
+        return;
+
+    /*
+     * Look the CIDs up by the connection, so that none of the paths that
+     * free a connection has to remember them.  A DTLS 1.3 connection can
+     * have more than one (RFC 9147 section 9).  An LHASH entry cannot be
+     * deleted inside doall, hence one at a time.
+     */
+    for (;;) {
+        ctx.ssl = ssl;
+        ctx.found = NULL;
+        lh_DGRAM_CONN_ENTRY_doall_void(lookup->htable, cid_find_ssl_cb, &ctx);
+        if (ctx.found == NULL)
+            return;
+
+        removed = lh_DGRAM_CONN_ENTRY_delete(lookup->htable, ctx.found);
+        conn_entry_free(removed);
+    }
+}
+
+size_t ossl_dgram_cid_lookup_num_items(const DGRAM_CID_LOOKUP *lookup)
+{
+    return lookup == NULL ? 0 : lh_DGRAM_CONN_ENTRY_num_items(lookup->htable);
+}
+
+void ossl_dgram_cid_lookup_free(DGRAM_CID_LOOKUP *lookup)
+{
+    if (lookup == NULL)
+        return;
+
+    lh_DGRAM_CONN_ENTRY_doall(lookup->htable, conn_entry_free_cb);
+    lh_DGRAM_CONN_ENTRY_free(lookup->htable);
+    OPENSSL_free(lookup);
+}
+
 #endif /* OPENSSL_NO_DTLS */
