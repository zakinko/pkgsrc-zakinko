$NetBSD$

3.34 は Singleton をやめ、singleton.h ごと落とした。GYP の側にはまだ
singleton だけを建てる target が残っているので外す。

入れ替わりに置く protobuf_util は 3.34 で現れたもので、renderer_style_handler
が要る。依存は BUILD.bazel の同名の target に合わせてある。

--- base/base.gyp.orig
+++ base/base.gyp
@@ -87,7 +87,6 @@
       'dependencies': [
         'base.gyp:version',
         'base_core',  # for logging, util, version
-        'singleton',
       ],
     },
     {
@@ -115,7 +114,6 @@
         'clock',
         'flags',
         'hash',
-        'singleton',
         'absl.gyp:absl_log',
         'absl.gyp:absl_random',
         'absl.gyp:absl_status',
@@ -200,14 +198,16 @@
       ],
     },
     {
-      'target_name': 'singleton',
+      'target_name': 'protobuf_util',
       'type': 'static_library',
       'toolsets': ['host', 'target'],
       'sources': [
-        'singleton.cc',
+        'protobuf_util.cc',
       ],
       'dependencies': [
-        'absl.gyp:absl_base',
+        '<(mozc_oss_src_dir)/protobuf/protobuf.gyp:protobuf',
+        'absl.gyp:absl_strings',
+        'base_core',
       ],
     },
     {
@@ -226,7 +226,6 @@
         'clock.cc',
       ],
       'dependencies': [
-        'singleton',
         'absl.gyp:absl_time',
       ],
     },
