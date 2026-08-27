$NetBSD$

codec_factory は codec に畳まれた。

--- dictionary/file/dictionary_file_test.gyp.orig
+++ dictionary/file/dictionary_file_test.gyp
@@ -40,7 +40,7 @@
         '<(mozc_oss_src_dir)/testing/testing.gyp:gtest_main',
         '<(mozc_oss_src_dir)/testing/testing.gyp:mozctest',
         'dictionary_file.gyp:codec',
-        'dictionary_file.gyp:codec_factory',
+        'dictionary_file.gyp:codec',
       ],
       'variables': {
         'test_size': 'small',
@@ -56,7 +56,7 @@
         '<(mozc_oss_src_dir)/base/base.gyp:base_core',
         '<(mozc_oss_src_dir)/testing/testing.gyp:gtest_main',
         '<(mozc_oss_src_dir)/testing/testing.gyp:mozctest',
-        'dictionary_file.gyp:codec_factory',
+        'dictionary_file.gyp:codec',
         'dictionary_file.gyp:dictionary_file',
         'dictionary_file.gyp:dictionary_file_builder',
       ],
