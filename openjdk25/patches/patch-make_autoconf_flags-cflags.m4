$NetBSD$

We prefer to use explicit run paths.

--- make/autoconf/flags-cflags.m4.orig	2026-09-15 06:57:08
+++ make/autoconf/flags-cflags.m4	2026-09-15 06:57:21
@@ -40,8 +40,8 @@
     # --disable-new-dtags forces use of RPATH instead of RUNPATH for rpaths.
     # This protects internal library dependencies within the JDK from being
     # overridden using LD_LIBRARY_PATH. See JDK-8326891 for more information.
-    SET_EXECUTABLE_ORIGIN='-Wl,-rpath,\$$ORIGIN[$]1 -Wl,--disable-new-dtags'
-    SET_SHARED_LIBRARY_ORIGIN="-Wl,-z,origin $SET_EXECUTABLE_ORIGIN"
+    SET_EXECUTABLE_ORIGIN='@COMPILER_RPATH_FLAG@@PREFIX@/java/@JAVA_NAME@/lib @COMPILER_RPATH_FLAG@@PREFIX@/java/@JAVA_NAME@/lib/server'
+    SET_SHARED_LIBRARY_ORIGIN="$SET_EXECUTABLE_ORIGIN"
     SET_SHARED_LIBRARY_NAME='-Wl,-soname=[$]1'
 
   elif test "x$TOOLCHAIN_TYPE" = xclang; then
@@ -62,19 +62,12 @@
     else
       # Default works for linux, might work on other platforms as well.
       SHARED_LIBRARY_FLAGS='-shared'
-      SET_EXECUTABLE_ORIGIN='-Wl,-rpath,\$$ORIGIN[$]1'
+      SET_EXECUTABLE_ORIGIN='@COMPILER_RPATH_FLAG@@PREFIX@/java/@JAVA_NAME@/lib @COMPILER_RPATH_FLAG@@PREFIX@/java/@JAVA_NAME@/lib/server'
       if test "x$OPENJDK_TARGET_OS" = xlinux; then
         SET_EXECUTABLE_ORIGIN="$SET_EXECUTABLE_ORIGIN -Wl,--disable-new-dtags"
       fi
       SET_SHARED_LIBRARY_NAME='-Wl,-soname=[$]1'
-
-      # arm specific settings
-      if test "x$OPENJDK_TARGET_CPU" = "xarm"; then
-        # '-Wl,-z,origin' isn't used on arm.
-        SET_SHARED_LIBRARY_ORIGIN='-Wl,-rpath,\$$$$ORIGIN[$]1'
-      else
-        SET_SHARED_LIBRARY_ORIGIN="-Wl,-z,origin $SET_EXECUTABLE_ORIGIN"
-      fi
+      SET_SHARED_LIBRARY_ORIGIN="$SET_EXECUTABLE_ORIGIN"
     fi
 
   elif test "x$TOOLCHAIN_TYPE" = xmicrosoft; then
