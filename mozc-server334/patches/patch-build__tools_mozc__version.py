$NetBSD$

NetBSD を platform の一覧に足す。番号は Linux と同じ 2 にしてある。ここは
版の文字列に入る数字で、gyp で建てたものと bazel で建てたものが同じ版として
扱われる必要がある。bazel 側は oss_linux として建てるので 2 になる。

--- build_tools/mozc_version.py.orig
+++ build_tools/mozc_version.py
@@ -67,6 +67,7 @@
     'iOS': '6',
     'iOS_sim': '6',
     'Wasm': '7',
+    'NetBSD': '2',
 }
 
 VERSION_PROPERTIES = [
