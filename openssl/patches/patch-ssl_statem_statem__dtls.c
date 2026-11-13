$NetBSD$

DTLS Connection IDs: RFC 9146, RFC 9853 and RFC 9147.
https://github.com/zakinko/openssl/tree/dtls-cid-series

--- ssl/statem/statem_dtls.c.orig
+++ ssl/statem/statem_dtls.c
@@ -438,7 +438,8 @@ int dtls1_do_write(SSL_CONNECTION *s, uint8_t recordtype)
                 if (!SSL_CONNECTION_IS_DTLS13(s)
                     || (s->statem.hand_state != TLS_ST_SW_SESSION_TICKET
                         && s->statem.hand_state != TLS_ST_CW_KEY_UPDATE
-                        && s->statem.hand_state != TLS_ST_SW_KEY_UPDATE))
+                        && s->statem.hand_state != TLS_ST_SW_KEY_UPDATE
+                        && !ossl_statem_is_cid_update_write(s->statem.hand_state)))
                     if (!ssl3_finish_mac(s, msgstart, xlen))
                         return -1;
             }
