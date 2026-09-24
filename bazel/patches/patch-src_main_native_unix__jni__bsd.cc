$NetBSD$

Say which of the optional interfaces NetBSD has.

This file is written for whichever BSD is compiling it and expects each to
declare what it offers.  NetBSD has neither extattr(2) nor
sysctlbyname(3), which is the same answer OpenBSD gives.

--- src/main/native/unix_jni_bsd.cc.orig	1980-01-01 00:00:00.000000000 +0000
+++ src/main/native/unix_jni_bsd.cc
@@ -15,6 +15,14 @@
 #if defined(__FreeBSD__)
 # define HAVE_EXTATTR
 # define HAVE_SYSCTLBYNAME
+#elif defined(__DragonFly__)
+// sys/extattr.h declares the whole extattr(2) family, but libc on 6.4
+// defines only the _file variants; the _link ones called below are
+// missing, so HAVE_EXTATTR would leave libunix_jni.so with an undefined
+// symbol.  sysctlbyname(3) is present.
+# define HAVE_SYSCTLBYNAME
+#elif defined(__NetBSD__)
+// No sys/extattr.h or sysctlbyname on this platform.
 #elif defined(__OpenBSD__)
 // No sys/extattr.h or sysctlbyname on this platform.
 #else
