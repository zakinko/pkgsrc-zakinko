$NetBSD: patch-src_search_c,v 1.2 2013/04/21 15:40:00 joerg Exp $

Include the standard headers.

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/regex19.c.orig
+++ src/regex19.c
@@ -25,6 +25,8 @@
   #pragma alloca
 #endif
 
+#include <stdlib.h>
+
 #define _GNU_SOURCE
 
 #ifdef HAVE_CONFIG_H
@@ -1552,7 +1554,7 @@
 /* 92.11.14 by enami */
 #define MASK_BITMAP(b,c) ((b)[(c) / BYTEWIDTH] |= 1 << ((c) % BYTEWIDTH))
 
-init_compile_charset_information (ip, b, p, pend, translate, mc_flag, skip)
+int init_compile_charset_information (ip, b, p, pend, translate, mc_flag, skip)
      struct compile_charset_information *ip;
      unsigned char *b;
      unsigned char *p, *pend;
@@ -3455,7 +3457,7 @@
 	case categoryspec:
 	case notcategoryspec:
 	  bufp->can_be_null = 1;
-	  return;
+	  return 0;
 #endif /* MULE */
 
       /* All cases after this match the empty string.  These end with
