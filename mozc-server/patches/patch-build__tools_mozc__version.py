$NetBSD$

Add NetBSD to the list of platforms.  The number is 2, the same as Linux.
It goes into the version string, and a build made with GYP has to be treated
as the same version as one made with Bazel.  The Bazel side builds as
oss_linux, which is 2.

--- build_tools/mozc_version.py.orig
+++ build_tools/mozc_version.py
@@ -67,6 +67,7 @@
     'iOS': '6',
     'iOS_sim': '6',
     'Wasm': '7',
+    'NetBSD': '2',
 }
 
 VERSION_PROPERTIES = [
