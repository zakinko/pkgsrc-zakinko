$NetBSD$

Declare the two FreeWnn pinyin functions that its headers leave out.

cplib.h carries macros with these names spelled with a leading underscore,
but nothing declares cwnn_yincod_pzy and cwnn_pzy_yincod themselves.  Both
return the length they produced, so both are int.

Declare the two FreeWnn pinyin functions that its headers leave out.

cplib.h carries macros with these names spelled with a leading underscore,
but nothing declares cwnn_yincod_pzy and cwnn_pzy_yincod themselves.  Both
return the length they produced, so both are int.

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

Pass and store pointers of the type the other side declares.

gcc 14 turned a pointer type mismatch into an error, so what used to be a
warning here now stops the build.  Where the declaration was simply wrong
it is corrected; where the system call or the library has moved since 1995
the value is converted at the call.

--- src/wnnfns.c.orig
+++ src/wnnfns.c
@@ -316,6 +316,16 @@
 #include "window.h"
 #include "charset.h"
 
+/* FreeWnn の中国語側の関数。cplib.h は同じ名前の巨視だけを置いていて、
+   関数そのものは宣言しない。どちらも長さを返すので int。  */
+extern int cwnn_yincod_pzy ();
+extern int cwnn_pzy_yincod ();
+
+/* FreeWnn の中国語側の関数。cplib.h は同じ名前の巨視だけを置いていて、
+   関数そのものは宣言しない。どちらも長さを返すので int。  */
+extern int cwnn_yincod_pzy ();
+extern int cwnn_pzy_yincod ();
+
 static struct wnn_buf *wnnfns_buf[NSERVER];
 static struct wnn_env *wnnfns_env_norm[NSERVER];
 static struct wnn_env *wnnfns_env_rev[NSERVER];
@@ -455,7 +465,7 @@
 		(args[5] == Qnil) ? 0 : XSTRING(args[5])->data,
 		(args[6] == Qnil) ? 0 : XSTRING(args[6])->data,
 		yes_or_no,
-		puts2 ) < 0) {
+		(int (*) ()) puts2 ) < 0) {
     UNGCPRO;
     return Qnil;
   }
@@ -1722,7 +1732,7 @@
     return make_number(serv);
 }
 
-syms_of_wnn()
+int syms_of_wnn()
 {
   int i;
 
@@ -1816,7 +1826,7 @@
   }
 }
 
-w2m(wp, mp, lc)
+int w2m(wp, mp, lc)
      w_char		*wp;
      unsigned char	*mp;
      unsigned char	lc;
@@ -1869,7 +1879,7 @@
   *mp = 0;
 }
 
-m2w(mp, wp)
+int m2w(mp, wp)
      unsigned char	*mp;
      w_char		*wp;
 {
@@ -1906,7 +1916,7 @@
   *wp = 0;
 }
 
-_xp(x)
+int _xp(x)
 int x;
 {
     printf("%x\n", x); fflush(stdout);
@@ -1940,7 +1950,7 @@
   }
 }
 
-c2m(cp, mp, lc)
+int c2m(cp, mp, lc)
      unsigned char	*cp;
      unsigned char	*mp;
      unsigned char	lc;
