$NetBSD$

Call only the finalizers that were registered.

finalizers is a 256 element array that starts out all null, and size
counts how many slots AddSingletonFinalizer has filled.  The loop
ignores size and walks the whole array, so the first unused slot is a
null function pointer call.  Since main() calls Finalize() on every
exit path, mozc_server dumps core whenever Run() returns early -- for
instance when another server already holds the process mutex, or when
the profile directory does not exist.

The 2.29 series counted down from size and did not have this; the
loop was rewritten in 3.33.  Upstream dropped Singleton entirely in
3.34, so this is fixed here.

--- base/singleton.cc.orig	2026-01-16 05:56:23.000000000 +0000
+++ base/singleton.cc
@@ -58,8 +58,8 @@ void AddSingletonFinalizer(void (*finali
 
 void FinalizeSingletons() ABSL_LOCKS_EXCLUDED(internal::mu) {
   absl::MutexLock lock(internal::mu);
-  for (auto func : internal::finalizers) {
-    func();
+  for (int i = 0; i < internal::size; ++i) {
+    internal::finalizers[i]();
   }
   internal::size = 0;
 }
