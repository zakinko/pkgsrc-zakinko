$NetBSD$

--- scripts/bootstrap/buildenv.sh.orig
+++ scripts/bootstrap/buildenv.sh
@@ -93,6 +93,11 @@
   JAVA_HOME="${JAVA_HOME:-/usr/local/openjdk11}"
   ;;
 
+netbsd)
+  # JAVA_HOME must point to a Java installation.
+  JAVA_HOME="${JAVA_HOME:-/usr/pkg/java/openjdk21}"
+  ;;
+
 openbsd)
   # JAVA_HOME must point to a Java installation.
   JAVA_HOME="${JAVA_HOME:-/usr/local/jdk-11}"
