$NetBSD$

NetBSD を Linux と同じ枝に入れる。

--- session/session.cc.orig
+++ session/session.cc
@@ -238,7 +238,7 @@
   // Tests for session layer (session_handler_scenario_test, etc) can be
   // unstable.
 #if (defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE) || defined(__linux__) || \
-    defined(__wasm__)
+    defined(__wasm__) || defined(__NetBSD__) || defined(__FreeBSD__)
   context->mutable_converter()->set_use_cascading_window(false);
 #endif  // TARGET_OS_IPHONE || __linux__ || __wasm__
 
@@ -1010,7 +1010,7 @@
   }
 
 #if (defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE) || defined(__linux__) || \
-    defined(__wasm__)
+    defined(__wasm__) || defined(__NetBSD__) || defined(__FreeBSD__)
   context_->mutable_converter()->set_use_cascading_window(false);
 #else   // TARGET_OS_IPHONE || __linux__ || __wasm__
   if (config.has_use_cascading_window()) {
