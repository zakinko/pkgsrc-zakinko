$NetBSD$

Two changes to the OpenSSL crypto plugin.

NetBSD has explicit_memset(3) and no explicit_bzero; map one onto the
other.

The hash size comes from EVP_MD_size(), which returns -1 on error and was
stored straight into a size_t, then used to size a variable-length array
on the stack in opensslcrypto_authenticate_and_decrypt().  Check the
value where it is obtained and size the array at EVP_MAX_MD_SIZE.  gcc
12 with NetBSD's _FORTIFY_SOURCE wrappers sees the unbounded size and
stops the -Werror build:

  error: '__builtin_memset' writing 18446744073709551615 bytes into a
  region of size between 0 and 9223372036854775807

--- libknet/crypto_openssl.c.orig
+++ libknet/crypto_openssl.c
@@ -13,6 +13,13 @@
 #include <errno.h>
 #include <dlfcn.h>
 #include <stdlib.h>
+/*
+ * NetBSD has explicit_memset(3) and no explicit_bzero.
+ */
+#ifdef __NetBSD__
+#define explicit_bzero(b, len)	explicit_memset((b), 0, (len))
+#endif
+
 #include <openssl/conf.h>
 #include <openssl/evp.h>
 #if (OPENSSL_VERSION_NUMBER < 0x30000000L)
@@ -459,7 +466,7 @@
 	ssize_t temp_len = buf_in_len;
 
 	if (instance->crypto_hash_type) {
-		unsigned char tmp_hash[crypto_instance->sec_hash_size];
+		unsigned char tmp_hash[EVP_MAX_MD_SIZE];
 		ssize_t temp_buf_len = buf_in_len - crypto_instance->sec_hash_size;
 
 		memset(tmp_hash, 0, sizeof(tmp_hash));
@@ -711,7 +718,18 @@
 	}
 
 	if (opensslcrypto_instance->crypto_hash_type) {
-		crypto_instance->sec_hash_size = EVP_MD_size(opensslcrypto_instance->crypto_hash_type);
+		int md_size = EVP_MD_size(opensslcrypto_instance->crypto_hash_type);
+
+		/*
+		 * EVP_MD_size() returns -1 on error, which as a size_t would
+		 * size the hash buffers at SIZE_MAX.
+		 */
+		if ((md_size <= 0) || (md_size > EVP_MAX_MD_SIZE)) {
+			log_err(knet_h, KNET_SUB_OPENSSLCRYPTO, "unusable hash size: %d", md_size);
+			savederrno = EINVAL;
+			goto out_err;
+		}
+		crypto_instance->sec_hash_size = md_size;
 	}
 
 	if (opensslcrypto_instance->crypto_cipher_type) {
