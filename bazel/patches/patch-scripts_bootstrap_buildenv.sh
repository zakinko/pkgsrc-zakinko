$NetBSD$

Point the bootstrap at the JDK pkgsrc installs.

Each system names its own default here.  Without an entry the bootstrap
runs with an empty JAVA_HOME and fails looking for javac.

--- scripts/bootstrap/buildenv.sh.orig
+++ scripts/bootstrap/buildenv.sh
@@ -93,6 +93,11 @@
   JAVA_HOME="${JAVA_HOME:-/usr/local/openjdk11}"
   ;;
 
+netbsd)
+  # JAVA_HOME must point to a Java installation.
+  JAVA_HOME="${JAVA_HOME:-@PKG_JAVA_HOME@}"
+  ;;
+
 openbsd)
   # JAVA_HOME must point to a Java installation.
   JAVA_HOME="${JAVA_HOME:-/usr/local/jdk-11}"
