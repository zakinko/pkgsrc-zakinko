$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- util/perl/OpenSSL/paramnames.pm.orig
+++ util/perl/OpenSSL/paramnames.pm
@@ -647,6 +647,8 @@ my %params = (
     'OSSL_LIBSSL_RECORD_LAYER_PARAM_MAX_EARLY_DATA' => "max_early_data",
     'OSSL_LIBSSL_RECORD_LAYER_PARAM_BLOCK_PADDING' =>  "block_padding",
     'OSSL_LIBSSL_RECORD_LAYER_PARAM_HS_PADDING' =>     "hs_padding",
+    'OSSL_LIBSSL_RECORD_LAYER_PARAM_DTLS_CID' =>       "dtls_cid",
+    'OSSL_LIBSSL_RECORD_LAYER_PARAM_DTLS_CID_MORE' =>  "dtls_cid_more",
 
 # Symmetric Key parameters
     'OSSL_SKEY_PARAM_ALIAS' => "skey-alias",
