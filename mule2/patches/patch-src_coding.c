$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/coding.c.orig
+++ src/coding.c
@@ -235,7 +235,7 @@
 }
 /* end of patch */
 
-code_detect_iso2022(buf, endp)
+int code_detect_iso2022(buf, endp)
      unsigned char *buf, *endp;
 {
   int mask = M_ISO_7 | M_ISO_8_1 | M_ISO_8_2 | M_ISO_ELSE;
@@ -289,7 +289,7 @@
   return mask;
 }
 
-code_detect_internal(buf, endp)
+int code_detect_internal(buf, endp)
      unsigned char *buf, *endp;
 {
   unsigned char c;
@@ -309,7 +309,7 @@
   return M_INT;
 }
 
-code_detect_sjis(buf, endp)
+int code_detect_sjis(buf, endp)
      unsigned char *buf, *endp;
 {
   unsigned char c;
@@ -327,7 +327,7 @@
   return M_SJIS;
 }
 
-code_detect_big5(buf, endp)
+int code_detect_big5(buf, endp)
      unsigned char *buf, *endp;
 {
   unsigned char c;
@@ -349,7 +349,7 @@
    If only ASCII, M_ALL is returned.
    If there's no possible coding system, M_BIN is returned. */
 
-code_detect(buf, n)
+int code_detect(buf, n)
      unsigned char *buf;
      int n;
 {
@@ -392,7 +392,7 @@
   return mask;
 }
 
-eol_detect(buf, n)
+int eol_detect(buf, n)
      unsigned char *buf;
      int n;
 {
@@ -614,7 +614,7 @@
 }
 
 /* ISO2022 Interpreter */
-i2g(src, dst, n, mccode)
+int i2g(src, dst, n, mccode)
      register unsigned char *src, *dst;
      unsigned int n;
      coding_type *mccode;
@@ -1052,7 +1052,7 @@
   cntl = (cntl & ~CC_GRAPHIC_MASK) | CC_IN_G3; \
 }
 
-g2i(src, dst, n, mccode)
+int g2i(src, dst, n, mccode)
      register unsigned char *src, *dst;
      unsigned int n;
      coding_type *mccode;
@@ -1399,7 +1399,7 @@
     Fsignal (Qcoding_system_error, code);
 }
 
-encode_code(code, mccode)
+int encode_code(code, mccode)
      Lisp_Object code;
      coding_type *mccode;
 {
@@ -1602,12 +1602,12 @@
 }
 #endif /* 0 */
 
-init_coding()
+int init_coding()
 {
   conv_buf_size = 0;
 }
 
-syms_of_coding ()
+int syms_of_coding ()
 {
   Lisp_Object val;
 
