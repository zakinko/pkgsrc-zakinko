$NetBSD$

singleton_test.cc と strings/zstring_view_test.cc は 3.34 に無い。
zstring_view_test は他に source を持たないので target ごと落とす。

--- base/base_test.gyp.orig
+++ base/base_test.gyp
@@ -106,7 +106,6 @@
         'container/bitarray_test.cc',
         'mmap_test.cc',
         'random_test.h',
-        'singleton_test.cc',
         'text_normalizer_test.cc',
         'thread_test.cc',
         'version_test.cc',
@@ -441,19 +440,6 @@
         'base.gyp:base',
       ],
     },
-    {
-      'target_name': 'zstring_view_test',
-      'type': 'executable',
-      'sources': [
-        'strings/zstring_view_test.cc',
-      ],
-      'dependencies': [
-        '<(mozc_oss_src_dir)/testing/testing.gyp:gtest_main',
-        'absl.gyp:absl_hash_testing',
-        'absl.gyp:absl_strings',
-        'base.gyp:base',
-      ],
-    },
     # Test cases meta target: this target is referred from gyp/tests.gyp
     {
       'target_name': 'base_all_test',
@@ -480,7 +466,6 @@
         'update_util_test',
         'url_test',
         'util_test',
-        'zstring_view_test',
       ],
       'conditions': [
         # To work around a link error on Ninja build, we put this target in
