$NetBSD$

time_zone_name_win.cc は abseil 20260107.1 で現れた Windows 専用の source で、
glob がそのまま拾ってしまう。3.34 が指している abseil は 3.33.6089 のものより
新しいので、GYP の側の除外一覧はそのぶん追いつかせる必要がある。

--- base/absl.gyp.orig
+++ base/absl.gyp
@@ -250,7 +250,7 @@
       'sources': [
         '<!@(<(glob_absl) time "*.cc")',
         '<!@(<(glob_absl) time/internal/cctz/src "*.cc"' +
-        ' --exclude time_tool.cc)',
+        ' --exclude time_tool.cc time_zone_name_win.cc)',
       ],
       'cflags': [
         '-Wno-error',
