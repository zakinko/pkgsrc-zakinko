$NetBSD$

NetBSD を Linux と同じ枝に入れる。xdg-open は pkgsrc の下に入る。

--- base/process.cc.orig
+++ base/process.cc
@@ -100,12 +100,12 @@
       L"open", win32::Utf8ToWide(url).c_str(), nullptr);
 #endif  // _WIN32
 
-#ifdef __linux__
+#if defined(__linux__) || defined(__NetBSD__) || defined(__FreeBSD__)
 
 #ifndef MOZC_BROWSER_COMMAND
   // xdg-open which uses kfmclient or gnome-open internally works both on KDE
   // and GNOME environments.
-#define MOZC_BROWSER_COMMAND "/usr/bin/xdg-open"
+#define MOZC_BROWSER_COMMAND "@PREFIX@/bin/xdg-open"
 #endif  // MOZC_BROWSER_COMMAND
 
   return SpawnProcess(MOZC_BROWSER_COMMAND, url);
@@ -189,7 +189,7 @@
   }
 #endif  // __APPLE__
 
-#ifdef __linux__
+#if defined(__linux__) || defined(__NetBSD__) || defined(__FreeBSD__)
   // Do not call posix_spawn() for obviously bad path.
   if (!S_ISREG(statbuf.st_mode)) {
     LOG(ERROR) << "Not a regular file: " << path;
@@ -389,7 +389,8 @@
   }
 #endif  // _WIN32
 
-#if defined(__linux__) && !defined(__ANDROID__)
+#if (defined(__linux__) || defined(__NetBSD__) || defined(__FreeBSD__)) && \
+    !defined(__ANDROID__)
   constexpr char kMozcTool[] = "mozc_tool";
   const std::string arg =
       absl::StrCat("--mode=error_message_dialog --error_type=", error_type);
