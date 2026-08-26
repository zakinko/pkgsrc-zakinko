$NetBSD: patch-session_session.cc,v 1.7 2024/02/10 01:17:28 ryoon Exp $

--- session/session.cc.orig
+++ session/session.cc
@@ -238,7 +238,7 @@
   // Tests for session layer (session_handler_scenario_test, etc) can be
   // unstable.
 #if (defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE) || defined(__linux__) || \
-    defined(__wasm__)
+    defined(__wasm__) || defined(__NetBSD__)
   context->mutable_converter()->set_use_cascading_window(false);
 #endif  // TARGET_OS_IPHONE || __linux__ || __wasm__
 
@@ -1007,7 +1007,7 @@
   }
 
 #if (defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE) || defined(__linux__) || \
-    defined(__wasm__)
+    defined(__wasm__) || defined(__NetBSD__)
   context_->mutable_converter()->set_use_cascading_window(false);
 #else   // TARGET_OS_IPHONE || __linux__ || __wasm__
   if (config.has_use_cascading_window()) {
