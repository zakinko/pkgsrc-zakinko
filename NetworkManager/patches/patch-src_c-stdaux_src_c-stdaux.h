$NetBSD$

Include the POSIX half of c-stdaux on the BSDs too.

See patch-src_c-stdaux_src_c-stdaux-generic.h for why C_OS_BSD exists.

--- src/c-stdaux/src/c-stdaux.h.orig
+++ src/c-stdaux/src/c-stdaux.h
@@ -46,7 +46,7 @@
 #  include <c-stdaux-gnuc.h>
 #endif
 
-#if defined(C_OS_LINUX) || defined(C_OS_MACOS)
+#if defined(C_OS_LINUX) || defined(C_OS_MACOS) || defined(C_OS_BSD)
 #  include <c-stdaux-unix.h>
 #endif
 
