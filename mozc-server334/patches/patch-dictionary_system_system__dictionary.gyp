$NetBSD$

codec_factory は codec に畳まれた。

--- dictionary/system/system_dictionary.gyp.orig
+++ dictionary/system/system_dictionary.gyp
@@ -63,7 +63,7 @@
         '<(mozc_oss_src_dir)/storage/louds/louds.gyp:bit_vector_based_array',
         '<(mozc_oss_src_dir)/storage/louds/louds.gyp:louds_trie',
         '<(mozc_oss_src_dir)/dictionary/dictionary_base.gyp:text_dictionary_loader',
-        '<(mozc_oss_src_dir)/dictionary/file/dictionary_file.gyp:codec_factory',
+        '<(mozc_oss_src_dir)/dictionary/file/dictionary_file.gyp:codec',
         '<(mozc_oss_src_dir)/dictionary/file/dictionary_file.gyp:dictionary_file',
         'key_expansion_table',
         'system_dictionary_codec',
@@ -79,7 +79,7 @@
         '<(mozc_oss_src_dir)/base/base.gyp:base_core',
         '<(mozc_oss_src_dir)/request/request.gyp:conversion_request',
         '<(mozc_oss_src_dir)/storage/louds/louds.gyp:louds_trie',
-        '<(mozc_oss_src_dir)/dictionary/file/dictionary_file.gyp:codec_factory',
+        '<(mozc_oss_src_dir)/dictionary/file/dictionary_file.gyp:codec',
         '<(mozc_oss_src_dir)/dictionary/pos_matcher.gyp:pos_matcher',
         'system_dictionary_codec',
       ],
@@ -98,7 +98,7 @@
         '<(mozc_oss_src_dir)/storage/louds/louds.gyp:louds_trie_builder',
         '<(mozc_oss_src_dir)/dictionary/dictionary_base.gyp:text_dictionary_loader',
         '<(mozc_oss_src_dir)/dictionary/file/dictionary_file.gyp:codec',
-        '<(mozc_oss_src_dir)/dictionary/file/dictionary_file.gyp:codec_factory',
+        '<(mozc_oss_src_dir)/dictionary/file/dictionary_file.gyp:codec',
         '<(mozc_oss_src_dir)/dictionary/pos_matcher.gyp:pos_matcher',
         'system_dictionary_codec',
       ],
