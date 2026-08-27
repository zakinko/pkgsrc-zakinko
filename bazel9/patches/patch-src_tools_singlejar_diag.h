$NetBSD$

Use err(3) rather than the fallback.

The list is of systems that have <err.h>; NetBSD is one of them, and the
replacement below it exists only for the systems that are not.

--- src/tools/singlejar/diag.h.orig
+++ src/tools/singlejar/diag.h
@@ -20,7 +20,7 @@
  * for portability.
  */
 #if defined(__APPLE__) || defined(__linux__) || defined(__FreeBSD__) || \
-    defined(__OpenBSD__)
+    defined(__OpenBSD__) || defined(__NetBSD__)
 
 #include <err.h>
 #define diag_err(...) err(__VA_ARGS__)
