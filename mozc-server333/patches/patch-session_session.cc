$NetBSD: patch-session_session.cc,v 1.7 2024/02/10 01:17:28 ryoon Exp $

Treat NetBSD like Linux here.  Upstream supports Linux, macOS, Windows,
Android and WASM only, so every POSIX path is spelled __linux__.

This disables the cascading candidate window, which needs a renderer.--- session/session.cc.orig
+++ session/session.cc
@@ -238,7 +238,8 @@
   // Tests for session layer (session_handler_scenario_test, etc) can be
   // unstable.
 #if (defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE) || defined(__linux__) || \
-    defined(__wasm__)
+    defined(__wasm__) || defined(__NetBSD__) || defined(__FreeBSD__) || \
+    defined(__OpenBSD__) || defined(__DragonFly__)
   context->mutable_converter()->set_use_cascading_window(false);
 #endif  // TARGET_OS_IPHONE || __linux__ || __wasm__
 
@@ -1007,7 +1008,8 @@
   }
 
 #if (defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE) || defined(__linux__) || \
-    defined(__wasm__)
+    defined(__wasm__) || defined(__NetBSD__) || defined(__FreeBSD__) || \
+    defined(__OpenBSD__) || defined(__DragonFly__)
   context_->mutable_converter()->set_use_cascading_window(false);
 #else   // TARGET_OS_IPHONE || __linux__ || __wasm__
   if (config.has_use_cascading_window()) {
