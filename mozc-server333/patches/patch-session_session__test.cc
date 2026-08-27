$NetBSD: patch-session_session__test.cc,v 1.5 2024/02/10 01:17:28 ryoon Exp $

Treat NetBSD like Linux here.  Upstream supports Linux, macOS, Windows,
Android and WASM only, so every POSIX path is spelled __linux__.

--- session/session_test.cc.orig
+++ session/session_test.cc
@@ -2128,7 +2128,7 @@
   const size_t cascading_cand_size =
       command.output().candidate_window().candidate_size();
 
-#if defined(__linux__) || defined(__wasm__)
+#if defined(__linux__) || defined(__wasm__) || defined(__NetBSD__)
   EXPECT_EQ(cascading_cand_size, no_cascading_cand_size);
 #else   // __linux__ || __wasm__
   EXPECT_GT(no_cascading_cand_size, cascading_cand_size);
@@ -2309,7 +2309,7 @@
 
     EXPECT_EQ(output.all_candidate_words().focused_index(), 0);
     EXPECT_EQ(output.all_candidate_words().category(), commands::CONVERSION);
-#if defined(__linux__) || defined(__wasm__)
+#if defined(__linux__) || defined(__wasm__) || defined(__NetBSD__)
     // Cascading window is not supported on Linux, so the size of
     // candidate words is different from other platform.
     // TODO(komatsu): Modify the client for Linux to explicitly change
@@ -2337,7 +2337,7 @@
 
     EXPECT_EQ(output.all_candidate_words().focused_index(), 1);
     EXPECT_EQ(output.all_candidate_words().category(), commands::CONVERSION);
-#if defined(__linux__) || defined(__wasm__)
+#if defined(__linux__) || defined(__wasm__) || defined(__NetBSD__)
     // Cascading window is not supported on Linux, so the size of
     // candidate words is different from other platform.
     // TODO(komatsu): Modify the client for Linux to explicitly change
