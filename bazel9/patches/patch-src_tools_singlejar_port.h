$NetBSD$

Take the same off64_t definition as the other BSDs.

off_t is already 64 bits here, so the typedef is the whole of it.

--- src/tools/singlejar/port.h.orig
+++ src/tools/singlejar/port.h
@@ -32,7 +32,7 @@
 typedef off_t off64_t;
 #elif defined(_WIN32)
 typedef __int64 off64_t;
-#elif defined(__OpenBSD__)
+#elif defined(__OpenBSD__) || defined(__NetBSD__)
 typedef int64_t off64_t;
 #endif
 static_assert(sizeof(off64_t) == 8, "File offset type must be 64-bit");
