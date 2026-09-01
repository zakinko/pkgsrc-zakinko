$NetBSD$

Give NetBSD a target platform digit.

TARGET_PLATFORM_TO_DIGIT replaces the last digit of REVISION with a
per-platform digit, so an entry is required or the version string is wrong.

'2' is deliberate: it is what a Linux build produces, so a GYP build and a
bazel build of the same release report the same version.  The client
refuses a server whose version string differs (client.cc,
CheckVersionOrRestartServer), and the digit does not appear in PKGNAME, so
a mismatch here is invisible to pkg_info.

--- build_tools/mozc_version.py.orig
+++ build_tools/mozc_version.py
@@ -67,6 +67,10 @@
     'iOS': '6',
     'iOS_sim': '6',
     'Wasm': '7',
+    'NetBSD': '2',
+    'FreeBSD': '2',
+    'OpenBSD': '2',
+    'DragonFly': '2',
 }
 
 VERSION_PROPERTIES = [
