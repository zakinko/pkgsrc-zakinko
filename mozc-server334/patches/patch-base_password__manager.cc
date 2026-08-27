$NetBSD$

NetBSD を Linux と同じ枝に入れる。

--- base/password_manager.cc.orig
+++ base/password_manager.cc
@@ -264,7 +264,8 @@
 // We use plain text file for password storage on Linux. If you port this module
 // to other Linux distro, you might want to implement a new password manager
 // which adopts some secure mechanism such like gnome-keyring.
-#if defined(__linux__) || defined(__wasm__)
+#if defined(__linux__) || defined(__wasm__) || defined(__NetBSD__) || \
+    defined(__FreeBSD__)
 typedef PlainPasswordManager DefaultPasswordManager;
 #endif  // __linux__ || __wasm__
 
