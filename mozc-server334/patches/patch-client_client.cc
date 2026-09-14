$NetBSD$

Put NetBSD on the same branch as Linux.

--- client/client.cc.orig
+++ client/client.cc
@@ -888,7 +888,8 @@
     return false;
   }
 
-#if defined(_WIN32) || defined(__linux__)
+#if defined(_WIN32) || defined(__linux__) || defined(__NetBSD__) || \
+    defined(__FreeBSD__)
   std::string arg = absl::StrCat("--mode=", mode);
   if (!extra_arg.empty()) {
     absl::StrAppend(&arg, " ", extra_arg);
