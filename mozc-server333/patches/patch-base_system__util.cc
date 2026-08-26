$NetBSD$

--- base/system_util.cc.orig
+++ base/system_util.cc
@@ -279,7 +279,7 @@
   return FileUtil::JoinPath(dir, "Mozc");
 #endif  //  GOOGLE_JAPANESE_INPUT_BUILD
 
-#elif defined(__linux__)
+#elif defined(__linux__) || defined(__NetBSD__)
   // 1. If "$HOME/.mozc" already exists,
   //    use "$HOME/.mozc" for backward compatibility.
   // 2. If $XDG_CONFIG_HOME is defined
@@ -454,9 +454,9 @@
   return MacUtil::GetServerDirectory();
 #endif  // __APPLE__
 
-#if defined(__linux__) || defined(__wasm__)
+#if defined(__linux__) || defined(__wasm__) || defined(__NetBSD__)
 #ifndef MOZC_SERVER_DIR
-#define MOZC_SERVER_DIR "/usr/lib/mozc"
+#define MOZC_SERVER_DIR "@PREFIX@/libexec"
 #endif  // MOZC_SERVER_DIR
   return MOZC_SERVER_DIR;
 #endif  // __linux__ || __wasm__
@@ -496,7 +496,7 @@
 #if defined(__linux__)
 
 #ifndef MOZC_DOCUMENT_DIR
-#define MOZC_DOCUMENT_DIR "/usr/lib/mozc/documents"
+#define MOZC_DOCUMENT_DIR "@PREFIX@/libexec/documents"
 #endif  // MOZC_DOCUMENT_DIR
   return MOZC_DOCUMENT_DIR;
 
@@ -690,7 +690,7 @@
 #endif  // _WIN32
 
 std::string SystemUtil::GetDesktopNameAsString() {
-#if defined(__linux__) || defined(__wasm__)
+#if defined(__linux__) || defined(__wasm__) || defined(__NetBSD__)
   return Environ::GetEnv("DISPLAY");
 #endif  // __linux__ || __wasm__
 
@@ -789,6 +789,9 @@
   const std::string ret = "MacOSX " + MacUtil::GetOSVersionString();
   // TODO(toshiyuki): get more specific info
   return ret;
+#elif defined(__NetBSD__)
+  const std::string ret = "NetBSD";
+  return ret;
 #elif defined(__linux__)
   const std::string ret = "Linux";
   return ret;
@@ -830,7 +833,7 @@
   return total_memory;
 #endif  // __APPLE__
 
-#if defined(__linux__) || defined(__wasm__)
+#if defined(__linux__) || defined(__wasm__) || defined(__NetBSD__)
 #if defined(_SC_PAGESIZE) && defined(_SC_PHYS_PAGES)
   const int32_t page_size = sysconf(_SC_PAGESIZE);
   const int32_t number_of_phyisical_pages = sysconf(_SC_PHYS_PAGES);
