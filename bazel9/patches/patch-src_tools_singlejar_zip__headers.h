$NetBSD$

Get the byte-order macros from <sys/endian.h>.

Same reason as src/main/cpp/util/md5.h: <endian.h> is glibc's spelling.

--- src/tools/singlejar/zip_headers.h.orig
+++ src/tools/singlejar/zip_headers.h
@@ -27,7 +27,7 @@
 
 #if defined(__linux__)
 #include <endian.h>
-#elif defined(__FreeBSD__) || defined(__OpenBSD__)
+#elif defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__NetBSD__)
 #include <sys/endian.h>
 #elif defined(__APPLE__) || defined(_WIN32)
 // Hopefully OSX and Windows will keep running solely on little endian CPUs, so:
