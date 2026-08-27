$NetBSD$

NetBSD の renderer は X11 を pkgsrc の下から引く。

あわせて renderer_style_handler に protobuf_util を繋ぐ。3.34 で
base/protobuf_util.h を読むようになった。

--- renderer/renderer.gyp.orig
+++ renderer/renderer.gyp
@@ -173,6 +173,7 @@
         'renderer_style_handler.cc',
       ],
       'dependencies': [
+        '<(mozc_oss_src_dir)/base/base.gyp:protobuf_util',
         '<(mozc_oss_src_dir)/protocol/protocol.gyp:renderer_proto',
       ],
       'variables': {
@@ -215,6 +216,71 @@
     },
   ],
   'conditions': [
+    ['use_qt=="YES" and (target_platform=="Linux" or target_platform=="NetBSD")', {
+      'targets': [
+        {
+          'target_name': 'gen_qt_renderer_files',
+          'type': 'none',
+          'variables': {
+            'subdir': 'qt',
+          },
+          'sources': [
+            'qt/qt_ipc_thread.h',
+            'qt/qt_server.h',
+          ],
+          'includes': [
+            '../gui/qt_moc.gypi',
+          ],
+        },
+        {
+          'target_name': 'qt_renderer_lib',
+          'type': 'static_library',
+          'sources': [
+            'qt/qt_ipc_server.cc',
+            'qt/qt_ipc_thread.cc',
+            'qt/qt_server.cc',
+            'qt/qt_window_manager.cc',
+            '<(gen_out_dir)/qt/moc_qt_ipc_thread.cc',
+            '<(gen_out_dir)/qt/moc_qt_server.cc',
+          ],
+          'dependencies': [
+            '<(mozc_oss_src_dir)/base/absl.gyp:absl_strings',
+            '<(mozc_oss_src_dir)/base/absl.gyp:absl_time',
+            '<(mozc_oss_src_dir)/base/base.gyp:base',
+            '<(mozc_oss_src_dir)/client/client.gyp:client',
+            '<(mozc_oss_src_dir)/config/config.gyp:config_handler',
+            '<(mozc_oss_src_dir)/ipc/ipc.gyp:ipc',
+            '<(mozc_oss_src_dir)/protocol/protocol.gyp:candidate_window_proto',
+            '<(mozc_oss_src_dir)/protocol/protocol.gyp:commands_proto',
+            '<(mozc_oss_src_dir)/protocol/protocol.gyp:config_proto',
+            '<(mozc_oss_src_dir)/protocol/protocol.gyp:renderer_proto',
+            'gen_qt_renderer_files',
+            'renderer_style_handler',
+            'window_util',
+          ],
+          'includes': [
+            '../gui/qt_libraries.gypi',
+          ],
+        },
+        {
+          'target_name': 'mozc_renderer',
+          'type': 'executable',
+          'sources': [
+            'qt/qt_renderer_main.cc',
+          ],
+          'defines': [
+            'ENABLE_QT_RENDERER',
+          ],
+          'dependencies': [
+            'init_mozc_renderer',
+            'qt_renderer_lib',
+          ],
+          'includes': [
+            '../gui/qt_libraries.gypi',
+          ],
+        },
+      ],
+    }],
     ['OS=="win"', {
       'targets': [
         {
