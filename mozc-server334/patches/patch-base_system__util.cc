$NetBSD$

NetBSD を Linux と同じ枝に入れ、置き場を pkgsrc のものにする。

3.34 は MOZC_SERVER_DIR を build 時に渡せるようになったが、gyp から文字列
マクロを渡すのは引用符の始末が要る。既定値の側を書き換える方が短い。

--- base/system_util.cc.orig
+++ base/system_util.cc
@@ -86,13 +86,13 @@
 #if defined(MOZC_SERVER_DIR)
 constexpr absl::string_view kMozcServerDir = MOZC_SERVER_DIR;
 #else  // MOZC_SERVER_DIR
-constexpr absl::string_view kMozcServerDir = "/usr/lib/mozc";
+constexpr absl::string_view kMozcServerDir = "@PREFIX@/libexec";
 #endif  // MOZC_SERVER_DIR
 
 #if defined(MOZC_DOCUMENT_DIR)
 constexpr absl::string_view kMozcDocumentDir = MOZC_DOCUMENT_DIR;
 #else  // MOZC_DOCUMENT_DIR
-constexpr absl::string_view kMozcDocumentDir = "/usr/lib/mozc/documents";
+constexpr absl::string_view kMozcDocumentDir = "@PREFIX@/libexec/documents";
 #endif  // MOZC_DOCUMENT_DIR
 
 class ProgramInvocationNameHolder final {
@@ -332,7 +332,7 @@
     return FileUtil::JoinPath(dir, "Mozc");
 #endif  //  GOOGLE_JAPANESE_INPUT_BUILD
 
-#elif defined(__linux__)
+#elif defined(__linux__) || defined(__NetBSD__) || defined(__FreeBSD__)
     // 1. If "$HOME/.mozc" already exists,
     //    use "$HOME/.mozc" for backward compatibility.
     // 2. If $XDG_CONFIG_HOME is defined
@@ -495,7 +495,8 @@
 #endif  // _WIN32
 
 std::string SystemUtil::GetServerDirectory() {
-  if constexpr (port::IsLinuxBase() || port::IsWasm()) {
+  if constexpr (port::IsLinuxBase() || port::IsWasm() || port::IsNetBSD() ||
+                port::IsFreeBSD()) {
     return std::string(kMozcServerDir);
   }
 
@@ -551,7 +552,7 @@
 }
 
 std::string SystemUtil::GetDocumentDirectory() {
-  if constexpr (port::IsLinuxBase()) {
+  if constexpr (port::IsLinuxBase() || port::IsNetBSD() || port::IsFreeBSD()) {
     return std::string(kMozcDocumentDir);
   } else if constexpr (port::IsAppleBase()) {
     return GetServerDirectory();
@@ -744,7 +745,8 @@
 #endif  // _WIN32
 
 std::string SystemUtil::GetDesktopNameAsString() {
-#if defined(__linux__) || defined(__wasm__)
+#if defined(__linux__) || defined(__wasm__) || defined(__NetBSD__) || \
+    defined(__FreeBSD__)
   return Environ::GetEnv("DISPLAY");
 #endif  // __linux__ || __wasm__
 
@@ -850,6 +852,10 @@
                           AndroidUtil::kSystemPropertyOsVersion, "Unknown"));
 #elif defined(__linux__)
   return "Linux";
+#elif defined(__NetBSD__)
+  return "NetBSD";
+#elif defined(__FreeBSD__)
+  return "FreeBSD";
 #else   // !_WIN32 && !__APPLE__ && !__linux__
   return "Unknown";
 #endif  // _WIN32, __APPLE__, __linux__
@@ -887,7 +893,8 @@
   return total_memory;
 #endif  // __APPLE__
 
-#if defined(__linux__) || defined(__wasm__)
+#if defined(__linux__) || defined(__wasm__) || defined(__NetBSD__) || \
+    defined(__FreeBSD__)
 #if defined(_SC_PAGESIZE) && defined(_SC_PHYS_PAGES)
   const int32_t page_size = sysconf(_SC_PAGESIZE);
   const int32_t number_of_phyisical_pages = sysconf(_SC_PHYS_PAGES);
