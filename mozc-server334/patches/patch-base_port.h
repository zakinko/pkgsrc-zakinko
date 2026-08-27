$NetBSD$

NetBSD と FreeBSD を platform の一覧に足す。

--- base/port.h.orig
+++ base/port.h
@@ -47,6 +47,8 @@
   kIos,       // iOS Devices or Simulator
   kWasm,      // WebAssembly
   kChromeos,  // ChromeOS
+  kNetBSD,    // NetBSD
+  kFreeBSD,   // FreeBSD
 };
 
 // kTargetPlatform is the current build target platform.
@@ -58,7 +60,11 @@
 #else                                        // OS_CHROMEOS
 inline constexpr PlatformType kTargetPlatform = PlatformType::kLinux;
 #endif                                       // !OS_CHROMEOS
-#elif defined(_WIN32)                        // __linux__
+#elif defined(__NetBSD__)                    // __linux__
+inline constexpr PlatformType kTargetPlatform = PlatformType::kNetBSD;
+#elif defined(__FreeBSD__)                   // __NetBSD__
+inline constexpr PlatformType kTargetPlatform = PlatformType::kFreeBSD;
+#elif defined(_WIN32)                        // __NetBSD__
 inline constexpr PlatformType kTargetPlatform = PlatformType::kWindows;
 #elif defined(__APPLE__)                     // _WIN32
 #if TARGET_OS_OSX
@@ -129,6 +135,16 @@
   return internal::kTargetPlatform == internal::PlatformType::kLinux;
 }
 
+// The build target is NetBSD.
+constexpr bool IsNetBSD() {
+  return internal::kTargetPlatform == internal::PlatformType::kNetBSD;
+}
+
+// The build target is FreeBSD.
+constexpr bool IsFreeBSD() {
+  return internal::kTargetPlatform == internal::PlatformType::kFreeBSD;
+}
+
 // The build target is Android.
 constexpr bool IsAndroid() {
   return internal::kTargetPlatform == internal::PlatformType::kAndroid;
