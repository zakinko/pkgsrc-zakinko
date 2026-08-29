$NetBSD: patch-ai,v 1.1 2007/06/11 13:38:35 markd Exp $

Mac OS X on x86 cannot dump: its dynamic loader does not let a process write
itself out as an executable.  Build the undumped emacs there instead.

--- src/m/intel386.h.orig	1997-08-30 07:18:39.000000000 +0000
+++ src/m/intel386.h
@@ -239,3 +239,7 @@ NOTE-END */
 
 #define SEGMENT_MASK ((SEGMENT_SIZE)-1)
 #endif
+
+#ifdef MAC_OSX
+#define CANNOT_DUMP
+#endif
