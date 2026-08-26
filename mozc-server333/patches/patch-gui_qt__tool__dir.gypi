$NetBSD$

--- gui/qt_tool_dir.gypi.orig
+++ gui/qt_tool_dir.gypi
@@ -32,10 +32,10 @@
   'variables': {
     'variables': {
       'conditions': [
-        ['qt_ver==6 and target_platform=="Linux"', {
+        ['qt_ver==6 and (target_platform=="Linux" or target_platform=="NetBSD")', {
           'qt_tool_dir': '<!(pkg-config --variable=libexecdir Qt6Core)',
         }],
-        ['qt_ver==5 and target_platform=="Linux"', {
+        ['qt_ver==5 and (target_platform=="Linux" or target_platform=="NetBSD")', {
           'qt_tool_dir': '<!(pkg-config --variable=host_bins Qt5Core)',
         }],
         ['qt_ver==6 and target_platform=="Mac"', {
