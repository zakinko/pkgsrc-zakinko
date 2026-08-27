$NetBSD: patch-gui_word__register__dialog_word__register__dialog.cc,v 1.7 2024/02/10 01:17:28 ryoon Exp $

Treat NetBSD like Linux here.  Upstream supports Linux, macOS, Windows,
Android and WASM only, so every POSIX path is spelled __linux__.

--- gui/word_register_dialog/word_register_dialog.cc.orig
+++ gui/word_register_dialog/word_register_dialog.cc
@@ -97,7 +97,7 @@
   }
   return QLatin1String("");
 #endif  // _WIN32
-#if defined(__APPLE__) || defined(__linux__)
+#if defined(__APPLE__) || defined(__linux__) || defined(__NetBSD__)
   return QString::fromUtf8(::getenv(envname));
 #endif  // __APPLE__ or __linux__
   // TODO(team): Support other platforms.
