$NetBSD: patch-make_autoconf_hotspot.m4,v 1.1 2023/11/22 14:06:50 ryoon Exp $

Name the build CPU zero as well when building the zero VM.

HOTSPOT_TARGET_CPU is set to zero here but HOTSPOT_BUILD_CPU is left at the
real one, and the build then looks for zero sources under the host's
architecture.  Only the zero variant reaches this, and it never builds any
other variant alongside, so naming both is safe.

--- make/autoconf/hotspot.m4.orig	2023-10-23 01:33:53.000000000 +0000
+++ make/autoconf/hotspot.m4
@@ -112,6 +112,8 @@ AC_DEFUN_ONCE([HOTSPOT_SETUP_MISC],
     # But when building zero, we never build any other variants so it works.
     HOTSPOT_TARGET_CPU=zero
     HOTSPOT_TARGET_CPU_ARCH=zero
+    HOTSPOT_BUILD_CPU=zero
+    HOTSPOT_BUILD_CPU_ARCH=zero
   fi
 
 
