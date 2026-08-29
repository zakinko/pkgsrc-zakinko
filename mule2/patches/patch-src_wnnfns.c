$NetBSD$

Declare the two FreeWnn pinyin functions that its headers leave out.

cplib.h carries macros with these names spelled with a leading underscore,
but nothing declares cwnn_yincod_pzy and cwnn_pzy_yincod themselves.  Both
return the length they produced, so both are int.

Declare the two FreeWnn pinyin functions that its headers leave out.

cplib.h carries macros with these names spelled with a leading underscore,
but nothing declares cwnn_yincod_pzy and cwnn_pzy_yincod themselves.  Both
return the length they produced, so both are int.

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
