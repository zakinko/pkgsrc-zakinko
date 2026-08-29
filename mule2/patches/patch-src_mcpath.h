$NetBSD$

Declare mc_access before the macro that redirects access to it.

The block below turns access into mc_access, so every caller that includes
this header calls a function it has never seen declared.  mc_access is
defined in mcpath.c returning int.

Declare mc_access before the macro that redirects access to it.

The block below turns access into mc_access, so every caller that includes
this header calls a function it has never seen declared.  mc_access is
defined in mcpath.c returning int.

--- src/mcpath.h.orig
+++ src/mcpath.h
@@ -119,6 +119,16 @@
 #      undef chdir
 #      undef opendir
 #      undef readdir
+
+/* この下で access を mc_access に置き換えるので、置き換えた先を先に
+   宣言しておく。定義は int を返す。  */
+extern int mc_access ();
+
+
+/* この下で access を mc_access に置き換えるので、置き換えた先を先に
+   宣言しておく。定義は int を返す。  */
+extern int mc_access ();
+
 #      define creat mc_creat
 #      define open mc_open
 #      define access mc_access
