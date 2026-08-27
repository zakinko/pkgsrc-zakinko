$NetBSD: patch-base_process.cc,v 1.7 2024/02/10 01:17:27 ryoon Exp $

Treat NetBSD like Linux here.  Upstream supports Linux, macOS, Windows,
Android and WASM only, so every POSIX path is spelled __linux__.

xdg-open lives under PREFIX in pkgsrc, not in /usr/bin.

--- base/process.cc.orig
+++ base/process.cc
@@ -101,12 +101,12 @@
       L"open", win32::Utf8ToWide(url).c_str(), nullptr);
 #endif  // _WIN32
 
-#ifdef __linux__
+#if defined(__linux__) || defined(__NetBSD__)
 
 #ifndef MOZC_BROWSER_COMMAND
   // xdg-open which uses kfmclient or gnome-open internally works both on KDE
   // and GNOME environments.
-#define MOZC_BROWSER_COMMAND "/usr/bin/xdg-open"
+#define MOZC_BROWSER_COMMAND "@PREFIX@/bin/xdg-open"
 #endif  // MOZC_BROWSER_COMMAND
 
   return SpawnProcess(MOZC_BROWSER_COMMAND, url);
@@ -389,7 +389,7 @@
   }
 #endif  // _WIN32
 
-#if defined(__linux__) && !defined(__ANDROID__)
+#if (defined(__linux__) || defined(__NetBSD__)) && !defined(__ANDROID__)
   constexpr char kMozcTool[] = "mozc_tool";
   const std::string arg =
       absl::StrCat("--mode=error_message_dialog --error_type=", error_type);
