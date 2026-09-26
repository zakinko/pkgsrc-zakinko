$NetBSD$

3.34 folded codec_factory.cc and codec_util.cc into codec.cc.  Each was the
only source of its target, so both targets go.

--- dictionary/file/dictionary_file.gyp.orig
+++ dictionary/file/dictionary_file.gyp
@@ -37,38 +37,11 @@
         'codec.cc',
       ],
       'dependencies': [
-        'codec_util',
         '<(mozc_oss_src_dir)/base/absl.gyp:absl_status',
         '<(mozc_oss_src_dir)/base/base.gyp:base_core',
       ],
     },
     {
-      'target_name': 'codec_factory',
-      'type': 'static_library',
-      'toolsets': ['target', 'host'],
-      'sources': [
-        'codec_factory.cc',
-      ],
-      'dependencies': [
-        'codec',
-        'codec_util',
-        '<(mozc_oss_src_dir)/base/base.gyp:base_core',
-      ],
-    },
-    {
-      'target_name': 'codec_util',
-      'type': 'static_library',
-      'toolsets': ['target', 'host'],
-      'sources': [
-        'codec_util.cc',
-      ],
-      'dependencies': [
-        '<(mozc_oss_src_dir)/base/absl.gyp:absl_strings',
-        '<(mozc_oss_src_dir)/base/absl.gyp:absl_status',
-        '<(mozc_oss_src_dir)/base/base.gyp:base_core',
-      ],
-    },
-    {
       'target_name': 'dictionary_file',
       'type': 'static_library',
       'toolsets': ['target', 'host'],
