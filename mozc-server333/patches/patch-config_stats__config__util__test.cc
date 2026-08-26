$NetBSD: patch-config_stats__config__util__test.cc,v 1.5 2024/02/10 01:17:27 ryoon Exp $

--- config/stats_config_util_test.cc.orig
+++ config/stats_config_util_test.cc
@@ -686,7 +686,7 @@
   EXPECT_FALSE(StatsConfigUtil::IsEnabled());
 #endif  // CHANNEL_DEV
 }
-#elif defined(__linux__)  // __ANDROID__
+#elif defined(__linux__) || defined(__NetBSD__)  // __ANDROID__
 TEST(StatsConfigUtilTestLinux, DefaultValueTest) {
   EXPECT_FALSE(StatsConfigUtil::IsEnabled());
 }
