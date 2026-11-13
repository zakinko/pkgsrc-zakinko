$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- test/ext_internal_test.c.orig
+++ test/ext_internal_test.c
@@ -53,6 +53,8 @@ static EXT_LIST ext_list[] = {
     EXT_EXCEPTION(use_srtp),
 #endif
     EXT_ENTRY(encrypt_then_mac),
+    EXT_ENTRY(connection_id),
+    EXT_ENTRY(rrc),
 #ifndef OPENSSL_NO_CT
     EXT_ENTRY(signed_certificate_timestamp),
 #else
