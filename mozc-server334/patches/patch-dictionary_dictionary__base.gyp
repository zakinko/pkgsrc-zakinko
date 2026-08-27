$NetBSD$

3.34 の user_pos は 3.33.6089 に無かったものを二つ要る。

一つは protocol/user_dictionary_storage.pb.h で、user_pos.h が読むように
なった。もう一つは dictionary/pos_cost_map.inc で、これは 3.34 で新しく
現れた生成物である。作り方は隣の gen_pos_map と同じ形で、data/rules の
user_pos.def から gen_pos_cost_map.py が起こす。

どちらも BUILD.bazel の同名の target が並べているものに合わせてある。

--- dictionary/dictionary_base.gyp.orig
+++ dictionary/dictionary_base.gyp
@@ -57,14 +57,49 @@
       'type': 'static_library',
       'toolsets': ['target', 'host'],
       'sources' : [
+        '<(gen_out_dir)/pos_cost_map.inc',
         'user_pos.cc',
       ],
       'dependencies': [
         '<(mozc_oss_src_dir)/base/absl.gyp:absl_strings',
         '<(mozc_oss_src_dir)/base/base.gyp:base',
+        '<(mozc_oss_src_dir)/protocol/protocol.gyp:user_dictionary_storage_proto',
+        'gen_pos_cost_map#host',
       ],
     },
     {
+      'target_name': 'gen_pos_cost_map',
+      'type': 'none',
+      'toolsets': ['host'],
+      'sources': [
+        '<(mozc_oss_src_dir)/build_tools/code_generator_util.py',
+        'gen_pos_cost_map.py',
+      ],
+
+      'actions': [
+        {
+          'action_name': 'gen_pos_cost_map',
+          'variables': {
+            'user_pos': '<(mozc_oss_src_dir)/data/rules/user_pos.def',
+            'pos_cost_map_header': '<(gen_out_dir)/pos_cost_map.inc',
+          },
+          'inputs': [
+            'gen_pos_cost_map.py',
+            '<(user_pos)',
+          ],
+          'outputs': [
+            '<(pos_cost_map_header)',
+          ],
+          'action': [
+            '<(python)', 'gen_pos_cost_map.py',
+            '--user_pos_file=<(user_pos)',
+            '--output=<(pos_cost_map_header)',
+          ],
+          'message': ('Generating <(pos_cost_map_header)'),
+        },
+      ],
+    },
+    {
       'target_name': 'gen_pos_map',
       'type': 'none',
       'toolsets': ['host'],
