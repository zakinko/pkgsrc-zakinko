$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- include/internal/dgram_conn_lookup.h.orig
+++ include/internal/dgram_conn_lookup.h
@@ -30,6 +30,7 @@
 
 /* Forward declarations */
 typedef struct dgram_conn_lookup_st DGRAM_CONN_LOOKUP;
+typedef struct dgram_cid_lookup_st DGRAM_CID_LOOKUP;
 typedef struct dgram_conn_lookup_methods_st DGRAM_CONN_LOOKUP_METHODS;
 
 /* Callback type for iterating over connections */
@@ -73,5 +74,63 @@ void ossl_dgram_conn_lookup_foreach(DGRAM_CONN_LOOKUP *lookup,
 void ossl_dgram_conn_lookup_free(DGRAM_CONN_LOOKUP *lookup);
 size_t ossl_dgram_conn_lookup_num_items(const DGRAM_CONN_LOOKUP *lookup);
 
+/*
+ * DGRAM_CID_LOOKUP - Connection ID based connection lookup for DTLS
+ * =================================================================
+ *
+ * Finds a connection by the Connection ID (RFC 9146) in a record.  The
+ * caller takes the CID out of the datagram, so the table holds byte strings
+ * and knows nothing of the record formats.  It does not own the SSL objects.
+ * Not internally synchronised: the caller holds the lock that serialises
+ * access, as for DGRAM_CONN_LOOKUP.
+ */
+
+/**
+ * @brief Create an empty CID lookup table.
+ * @returns the table, or NULL on allocation failure
+ */
+DGRAM_CID_LOOKUP *ossl_dgram_cid_lookup_new(void);
+
+/**
+ * @brief Find the connection registered under a CID.
+ * @param lookup the table
+ * @param cid the CID bytes
+ * @param cid_len the length of @p cid
+ * @returns the connection, or NULL if none
+ */
+SSL *ossl_dgram_cid_lookup_find(DGRAM_CID_LOOKUP *lookup,
+    const unsigned char *cid, size_t cid_len);
+
+/**
+ * @brief Register a connection under a CID that is not registered yet.
+ * @param lookup the table
+ * @param cid the CID bytes, copied
+ * @param cid_len the length of @p cid
+ * @param ssl the connection
+ * @returns 1 on success, 0 on failure or if @p cid is already registered
+ */
+int ossl_dgram_cid_lookup_register(DGRAM_CID_LOOKUP *lookup,
+    const unsigned char *cid, size_t cid_len, SSL *ssl);
+
+/**
+ * @brief Remove whatever CID a connection is registered under, if any.
+ * @param lookup the table
+ * @param ssl the connection
+ */
+void ossl_dgram_cid_lookup_unregister_ssl(DGRAM_CID_LOOKUP *lookup, SSL *ssl);
+
+/**
+ * @brief Count the registered CIDs.
+ * @param lookup the table
+ * @returns the number of entries
+ */
+size_t ossl_dgram_cid_lookup_num_items(const DGRAM_CID_LOOKUP *lookup);
+
+/**
+ * @brief Free the table and its entries, not the connections.
+ * @param lookup the table, may be NULL
+ */
+void ossl_dgram_cid_lookup_free(DGRAM_CID_LOOKUP *lookup);
+
 #endif /* OPENSSL_NO_DTLS */
 #endif /* OSSL_INTERNAL_DGRAM_CONN_LOOKUP_H */
