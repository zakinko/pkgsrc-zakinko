$NetBSD$

Let c-stdaux recognise the BSDs.

c-stdaux derives C_OS_LINUX, C_OS_MACOS and C_OS_WINDOWS and knows nothing
else, and c-stdaux.h includes c-stdaux-unix.h only for the first two.  On any
BSD neither is defined, so that header - c_close(), c_closep(), c_fclosep()
and the rest - is left out entirely.

Nothing in c-stdaux-unix.h is Linux-specific.  It includes dirent.h, fcntl.h,
sys/time.h, sys/types.h and unistd.h, and everything it declares is plain
POSIX.

The symptom is not a missing declaration but

	error: cleanup argument not a function

wherever _c_cleanup_(c_closep) appears, which points at the attribute rather
than at the absent function and is correspondingly hard to read.

--- src/c-stdaux/src/c-stdaux-generic.h.orig
+++ src/c-stdaux/src/c-stdaux-generic.h
@@ -68,6 +68,11 @@
 #  define C_OS_MACOS 1
 #endif
 
+#if defined(__FreeBSD__) || defined(__NetBSD__) || \
+    defined(__OpenBSD__) || defined(__DragonFly__)
+#  define C_OS_BSD 1
+#endif
+
 #if defined(_WIN32) || defined(_WIN64)
 #  define C_OS_WINDOWS 1
 #endif
