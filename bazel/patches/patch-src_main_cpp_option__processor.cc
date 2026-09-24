$NetBSD$

Read the netbsd arm of .bazelrc.

bazel picks a platform_config name here and then honours "build:netbsd"
lines in the rc files.  Without an entry, no such line is ever selected.

--- src/main/cpp/option_processor.cc.orig	1980-01-01 00:00:00.000000000 +0000
+++ src/main/cpp/option_processor.cc
@@ -628,6 +628,8 @@ blaze_exit_code::ExitCode OptionProcesso
   platform_config = "windows";
 #elif defined(__FreeBSD__)
   platform_config = "freebsd";
+#elif defined(__NetBSD__) || defined(__DragonFly__)
+  platform_config = "netbsd";
 #elif defined(__OpenBSD__)
   platform_config = "openbsd";
 #endif
