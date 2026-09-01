$NetBSD$

Declare mc_access before the macro that redirects access to it.

The block below turns access into mc_access, so every caller that includes
this header calls a function it has never seen declared.  mc_access is
defined in mcpath.c returning int.

Declare mc_access before the macro that redirects access to it.

The block below turns access into mc_access, so every caller that includes
this header calls a function it has never seen declared.  mc_access is
defined in mcpath.c returning int.

Keep the added headers out of the Makefile-generating pass.

config.h is read twice: once by the compiler, and once by the cpp run that
turns Makefile.in into Makefile.  The second one is traditional cpp and
cannot read a modern glibc header at all, so the includes have to sit
inside #ifndef NOT_C_CODE, the way s/irix4-0.h does it.

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
@@ -151,6 +161,14 @@
 #      endif /* !NO_MC_EXECVP */
 #      define opendir mc_opendir
 #      define readdir mc_readdir
+
+/* 差し替えた直後にヘッダを読む。こうすると <fcntl.h> などが宣言するのは
+   mc_open や mc_stat になり、mcpath.c が用意する実体と名前が揃う。
+   K&R の extern int mc_open (); では駄目で、open は可変長引数なので
+   原型と両立しない。 */
+#      include <fcntl.h>
+#      include <unistd.h>
+#      include <sys/stat.h>
 #      ifdef HAVE_MKDIR					/* hir, 1994.8.12 */
 #	 define mkdir mc_mkdir
 #      endif
