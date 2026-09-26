$NetBSD$

Name the JDK in the self-extracting installer.

This template becomes the shell installer bazel ships for people who do
not use a package manager.  pkgsrc does not run it, but leaving NetBSD out
of a list that names FreeBSD and OpenBSD would be an odd thing to hand
upstream.

--- scripts/packages/template_bin.sh.orig
+++ scripts/packages/template_bin.sh
@@ -115,6 +115,10 @@
       JAVA_HOME="/usr/local/openjdk8"
       BASHRC="~/.bashrc"
       ;;
+    netbsd)
+      JAVA_HOME="@PKG_JAVA_HOME@"
+      BASHRC="~/.bashrc"
+      ;;
     openbsd)
       JAVA_HOME="/usr/local/jdk-1.8.0"
       BASHRC="~/.bashrc"
