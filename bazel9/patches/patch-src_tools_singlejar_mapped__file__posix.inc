$NetBSD$

Let singlejar build on 64-bit NetBSD.

The guard is a list of systems this mmap-based implementation has been
written for, and NetBSD behaves as the others do.  The 64-bit requirement
is left alone: it is why bazel cannot be built for i386 at all.

--- src/tools/singlejar/mapped_file_posix.inc.orig	1980-01-01 00:00:00.000000000 +0000
+++ src/tools/singlejar/mapped_file_posix.inc
@@ -26,7 +26,7 @@
 
 // The implementation is specific to 64-bit Linux / OS X / BSD.
 #if !((defined(__linux__) || defined(__APPLE__) || defined(__FreeBSD__) || \
-       defined(__OpenBSD__)) &&                                            \
+       defined(__OpenBSD__) || defined(__NetBSD__) || defined(__DragonFly__)) &&                     \
       __SIZEOF_POINTER__ == 8)
 #error This code for 64 bit Unix.
 #endif
