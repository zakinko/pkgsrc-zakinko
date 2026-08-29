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

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

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
@@ -196,10 +202,10 @@
 
 #ifdef CANNA_MULE
 #if __STDC__
-static m2c(unsigned char *, int, unsigned char *);
+static int m2c(unsigned char *, int, unsigned char *);
 static Lisp_Object mule_make_string(unsigned char *, int);
-static mule_strlen(unsigned char *, int);
-static count_char(unsigned char *,int, int, int, int *, int *, int *);
+static int mule_strlen(unsigned char *, int);
+static int count_char(unsigned char *,int, int, int, int *, int *, int *);
 #else
 static m2c();
 static Lisp_Object mule_make_string();
@@ -407,7 +413,7 @@
     return Fcons(Qnil, val);
   }
   else {
-    extern (*jrBeepFunc)();
+    extern int (*jrBeepFunc)();
     Lisp_Object Fding(), CANNA_mode_keys();
 
     jrBeepFunc = Fding;
@@ -664,7 +670,7 @@
 static unsigned char yomibuf[RKBUFSIZE];
 static short kugiri[RKBUFSIZE / 2];
 
-static confirmContext()
+static int confirmContext()
 {
   if (IRCP_context < 0) {
     int context;
@@ -677,7 +683,7 @@
   return 1;
 }
 
-static byteLen(bun, len)
+static int byteLen(bun, len)
 int bun, len;
 {
   int i = 0, offset = 0, ch;
@@ -985,7 +991,7 @@
 
 static Lisp_Object VCANNA;				/* hir@nec, 1992.5.21 */
 
-syms_of_canna ()
+int syms_of_canna ()
 {
   DEFVAR_LISP ("CANNA", &VCANNA, "");		/* hir@nec, 1992.5.21 */
   VCANNA = Qt;					/* hir@nec, 1992.5.21 */
@@ -1208,7 +1214,7 @@
 /* EUC multibyte string to MULE internal string */
 
 static
-c2mu(cp, l, mp)
+int c2mu(cp, l, mp)
 char	*cp;
 int	l;
 char	*mp;
@@ -1237,7 +1243,7 @@
 /* MULE internal string to EUC multibyte string */
 
 static
-m2c(mp, l, cp)
+int m2c(mp, l, cp)
 unsigned char	*mp;
 int	l;
 unsigned char	*cp;
@@ -1281,7 +1287,7 @@
 
 /* return the MULE internal string length of EUC string */
 static
-mule_strlen(p,l)
+int mule_strlen(p,l)
 unsigned char *p;
 int l;
 {
@@ -1311,14 +1317,14 @@
 
 /* count number of characters */
 static
-count_char(p,len,pos,rev,clen,cpos,crev)
+int count_char(p,len,pos,rev,clen,cpos,crev)
 unsigned char *p;	
 int len,pos,rev,*clen,*cpos,*crev;
 {
   unsigned char *q = p;
   
   *clen = *cpos = *crev = 0;
-  if (len == 0) return;
+  if (len == 0) return 0;
   while (q < p + pos) {
     (*clen)++;
     (*cpos)++;
