$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- test/helpers/ssltestlib.c.orig
+++ test/helpers/ssltestlib.c
@@ -314,6 +314,7 @@ typedef struct mempacket_test_ctx_st {
     unsigned int dropepoch;
     int droprec;
     int duprec;
+    size_t cidlen;
 } MEMPACKET_TEST_CTX;
 
 static int mempacket_test_new(BIO *bi);
@@ -408,7 +409,13 @@ static int mempacket_test_read(BIO *bio, char *out, int outl)
             unsigned int rechdrlen;
 
             if (DTLS13_UNI_HDR_FIX_BITS_IS_SET(*rec))
-                rechdrlen = DTLS13_UNI_HDR_FIXED_LENGTH;
+                rechdrlen = DTLS13_UNI_HDR_FIXED_LENGTH
+                    + (DTLS13_UNI_HDR_CID_BIT_IS_SET(*rec)
+                            ? (unsigned int)ctx->cidlen
+                            : 0);
+            else if (*rec == SSL3_RT_TLS12_CID && ctx->cidlen != 0)
+                /* RFC 9146 section 4, Figure 3: the CID before the length */
+                rechdrlen = DTLS1_RT_HEADER_LENGTH + (unsigned int)ctx->cidlen;
             else
                 rechdrlen = DTLS1_RT_HEADER_LENGTH;
 
@@ -436,10 +443,9 @@ static int mempacket_test_read(BIO *bio, char *out, int outl)
             }
 
             if (DTLS13_UNI_HDR_FIX_BITS_IS_SET(*rec))
-                len = (rec[DTLS13_UNI_HDR_RECORD_LEN_HI] << 8)
-                    | rec[DTLS13_UNI_HDR_RECORD_LEN_LO];
+                len = (rec[rechdrlen - 2] << 8) | rec[rechdrlen - 1];
             else
-                len = (rec[RECORD_LEN_HI] << 8) | rec[RECORD_LEN_LO];
+                len = (rec[rechdrlen - 2] << 8) | rec[rechdrlen - 1];
 
             len += rechdrlen;
 
@@ -910,17 +916,31 @@ int mempacket_test_inject(BIO *bio, const char *in, int inl, int pktnum,
     size_t len;
 
     if (DTLS13_UNI_HDR_FIX_BITS_IS_SET(*in)
-        /* The following code does not handle connection ids */
-        && ossl_assert(!DTLS13_UNI_HDR_CID_BIT_IS_SET(*in))) {
+        /* A CID can only be framed with its length set on the BIO */
+        && (!DTLS13_UNI_HDR_CID_BIT_IS_SET(*in)
+            || (ctx != NULL && ctx->cidlen != 0))) {
+        /* RFC 9147 section 4, Figure 3: any CID follows the first byte */
+        size_t cid = DTLS13_UNI_HDR_CID_BIT_IS_SET(*in) ? ctx->cidlen : 0;
+
         if (DTLS13_UNI_HDR_LEN_BIT_IS_SET(*in)) {
+            if ((size_t)inl < DTLS13_UNI_HDR_RECORD_LEN_LO + 1 + cid)
+                return -1;
             len = 3; /* 2 bytes for len field and 1 byte for record type */
             len += DTLS13_UNI_HDR_SEQ_BIT_IS_SET(*in) ? 2 : 1;
-            len += ((inu[DTLS13_UNI_HDR_RECORD_LEN_HI] << 8)
-                | inu[DTLS13_UNI_HDR_RECORD_LEN_LO]);
+            len += cid;
+            len += ((inu[DTLS13_UNI_HDR_RECORD_LEN_HI + cid] << 8)
+                | inu[DTLS13_UNI_HDR_RECORD_LEN_LO + cid]);
         } else {
             /* We assert that inl is the correct record length */
             len = inl;
         }
+    } else if (*in == SSL3_RT_TLS12_CID && ctx != NULL && ctx->cidlen != 0) {
+        /* RFC 9146 section 4, Figure 3: the CID before the length */
+        if ((size_t)inl < DTLS1_RT_HEADER_LENGTH + ctx->cidlen)
+            return -1;
+        len = ((inu[RECORD_LEN_HI + ctx->cidlen] << 8)
+            | inu[RECORD_LEN_LO + ctx->cidlen]);
+        len += DTLS1_RT_HEADER_LENGTH + ctx->cidlen;
     } else {
         len = ((inu[RECORD_LEN_HI] << 8) | inu[RECORD_LEN_LO]);
         len += DTLS1_RT_HEADER_LENGTH;
@@ -1075,6 +1095,9 @@ static long mempacket_test_ctrl(BIO *bio, int cmd, long num, void *ptr)
     case MEMPACKET_CTRL_SET_DUPLICATE_REC:
         ctx->duprec = (int)num;
         break;
+    case MEMPACKET_CTRL_SET_CID_LEN:
+        ctx->cidlen = (size_t)num;
+        break;
     case BIO_CTRL_DGRAM_QUERY_MTU:
         ret = 1500;
         break;
