$NetBSD$

Fwnn_word_info casts the pointer it just got from jl_word_info() to int and
tests it for <= 0.  jl_word_info_e returns a struct wnn_jdata *, so on LP64
the cast keeps only the low 32 bits: an address whose low half happens to
have the sign bit set reads as negative and a successful lookup is thrown
away.  Compare against NULL instead, which is what the library returns when
it fails.

The cast is dated 92.10.19 in the source, added to silence a warning back
when int and a pointer were the same width.

--- src/wnn4fns.c.orig
+++ src/wnn4fns.c
@@ -882,9 +882,12 @@
   lc = lc_wnn_server_type[snum];
   if(!wnnfns_buf[snum]) return Qnil;
   /* 92.10.19 patch by T.Atsushiba <atsushiba@ailove.ENET.dec.com>
-     -- coerced to (int) */
-  if((int)(info_buf =  jl_word_info(wnnfns_buf[snum],
-				 XINT(no), XINT(serial))) <= 0) {
+     -- coerced to (int).  Undone: jl_word_info_e returns a
+     struct wnn_jdata *, and the cast throws away the top half of it
+     on LP64.  Compare against NULL, which is what the library
+     returns on failure.  */
+  if((info_buf =  jl_word_info(wnnfns_buf[snum],
+				 XINT(no), XINT(serial))) == NULL) {
     return Qnil;
   } else {
     val = Qnil;
