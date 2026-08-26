$NetBSD$

--- scripts/packages/template_bin.sh.orig
+++ scripts/packages/template_bin.sh
@@ -115,6 +115,10 @@
       JAVA_HOME="/usr/local/openjdk8"
       BASHRC="~/.bashrc"
       ;;
+    netbsd)
+      JAVA_HOME="/usr/pkg/java/openjdk21"
+      BASHRC="~/.bashrc"
+      ;;
     openbsd)
       JAVA_HOME="/usr/local/jdk-1.8.0"
       BASHRC="~/.bashrc"
