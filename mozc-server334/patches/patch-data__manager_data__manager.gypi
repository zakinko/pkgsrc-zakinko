$NetBSD$

版の定義の移動。patch-build__mozc.py と同じ理由。

--- data_manager/data_manager.gypi.orig
+++ data_manager/data_manager.gypi
@@ -989,7 +989,7 @@
           'action_name': 'gen_separate_version_data_for_<(dataset_tag)',
           'variables': {
             'generator': '<(mozc_dir)/data_manager/gen_data_version.py',
-            'version_file': '<(mozc_oss_src_dir)/data/version/mozc_version_template.bzl',
+            'version_file': '<(mozc_oss_src_dir)/version.bzl',
           },
           'inputs': [
             '<(generator)',
