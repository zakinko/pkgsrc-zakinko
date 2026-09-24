$NetBSD$

time_zone_name_win.cc is a Windows-only source that appeared in abseil
20260107.1, and the glob picks it up regardless.  The abseil 3.34 points at is
newer than the one 3.33.6089 used, so the exclusion list on the GYP side has
to catch up by that much.

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
