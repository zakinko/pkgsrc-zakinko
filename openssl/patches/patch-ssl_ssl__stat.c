$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/ssl_stat.c.orig
+++ ssl/ssl_stat.c
@@ -132,6 +132,22 @@ const char *SSL_state_string_long(const SSL *s)
         return "DTLSv1.3 read server ack";
     case TLS_ST_SW_ACK:
         return "DTLSv1.3 write server ack";
+    case TLS_ST_CR_NEW_CONNECTION_ID:
+        return "DTLSv1.3 read server new connection id";
+    case TLS_ST_CW_NEW_CONNECTION_ID:
+        return "DTLSv1.3 write client new connection id";
+    case TLS_ST_SR_NEW_CONNECTION_ID:
+        return "DTLSv1.3 read client new connection id";
+    case TLS_ST_SW_NEW_CONNECTION_ID:
+        return "DTLSv1.3 write server new connection id";
+    case TLS_ST_CR_REQUEST_CONNECTION_ID:
+        return "DTLSv1.3 read server request connection id";
+    case TLS_ST_CW_REQUEST_CONNECTION_ID:
+        return "DTLSv1.3 write client request connection id";
+    case TLS_ST_SR_REQUEST_CONNECTION_ID:
+        return "DTLSv1.3 read client request connection id";
+    case TLS_ST_SW_REQUEST_CONNECTION_ID:
+        return "DTLSv1.3 write server request connection id";
     default:
         return "unknown state";
     }
@@ -257,6 +273,22 @@ const char *SSL_state_string(const SSL *s)
         return "TRSACK";
     case TLS_ST_SW_ACK:
         return "TWSACK";
+    case TLS_ST_CR_NEW_CONNECTION_ID:
+        return "TRSNCI";
+    case TLS_ST_CW_NEW_CONNECTION_ID:
+        return "TWCNCI";
+    case TLS_ST_SR_NEW_CONNECTION_ID:
+        return "TRCNCI";
+    case TLS_ST_SW_NEW_CONNECTION_ID:
+        return "TWSNCI";
+    case TLS_ST_CR_REQUEST_CONNECTION_ID:
+        return "TRSRCI";
+    case TLS_ST_CW_REQUEST_CONNECTION_ID:
+        return "TWCRCI";
+    case TLS_ST_SR_REQUEST_CONNECTION_ID:
+        return "TRCRCI";
+    case TLS_ST_SW_REQUEST_CONNECTION_ID:
+        return "TWSRCI";
     default:
         return "UNKWN";
     }
