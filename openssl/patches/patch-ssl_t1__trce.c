$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/t1_trce.c.orig
+++ ssl/t1_trce.c
@@ -89,6 +89,8 @@ static const ssl_trace_tbl ssl_handshake_tbl[] = {
     { SSL3_MT_NEWSESSION_TICKET, "NewSessionTicket" },
     { SSL3_MT_END_OF_EARLY_DATA, "EndOfEarlyData" },
     { SSL3_MT_ENCRYPTED_EXTENSIONS, "EncryptedExtensions" },
+    { SSL3_MT_REQUEST_CONNECTION_ID, "RequestConnectionId" },
+    { SSL3_MT_NEW_CONNECTION_ID, "NewConnectionId" },
     { SSL3_MT_CERTIFICATE, "Certificate" },
     { SSL3_MT_SERVER_KEY_EXCHANGE, "ServerKeyExchange" },
     { SSL3_MT_CERTIFICATE_REQUEST, "CertificateRequest" },
