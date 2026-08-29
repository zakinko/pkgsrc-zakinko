$NetBSD: patch-src_canna.c,v 1.1 2013/04/21 15:39:59 joerg Exp $

The function is declared to return a value and falls off the end
without one, handing the caller whatever was in the return register.

Declare wcKanjiControl, which canna/jrkanji.h hides.

The header only declares the wide-character entry points inside
CANNAWC_DEFINED, which it sets when _WCHAR_T or CANNA_NEW_WCHAR_AWARE is
defined.  This tree defines neither, so the call went out with no
declaration at all.

Defining CANNA_NEW_WCHAR_AWARE here would fix the warning too, but it also
renames the symbol to cannawcKanjiControl and changes the wide character
type, which is a different call.  The declaration is the smaller change and
keeps the link exactly as it is.

--- src/canna.c.orig
+++ src/canna.c
@@ -149,6 +149,12 @@
 #include "config.h"
 #include "lisp.h"
 #include "buffer.h"
+
+/* canna/jrkanji.h は wcKanjiControl を CANNAWC_DEFINED の内側でしか
+   宣言しない。あれは _WCHAR_T か CANNA_NEW_WCHAR_AWARE が立っていると
+   きだけで、この木はどちらも立てない。呼んでいる形は変えたくないので、
+   ここで宣言だけしておく。戻り値は int。  */
+extern int wcKanjiControl ();
 #ifdef CANNA_MULE
 #include "charset.h"
 #endif
@@ -1318,7 +1324,7 @@
   unsigned char *q = p;
   
   *clen = *cpos = *crev = 0;
-  if (len == 0) return;
+  if (len == 0) return 0;
   while (q < p + pos) {
     (*clen)++;
     (*cpos)++;
