$NetBSD$

user_pos in 3.34 needs two things that 3.33.6089 did not have.

One is protocol/user_dictionary_storage.pb.h, which user_pos.h now includes.
The other is dictionary/pos_cost_map.inc, a generated file that is new in
3.34; it is produced the same way as gen_pos_map next to it, by
gen_pos_cost_map.py out of data/rules/user_pos.def.

Both match what the target of the same name in BUILD.bazel lists.

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
