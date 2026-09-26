$NetBSD$

Give s6_addr32 a name on the BSDs that keep it in the kernel.

glibc offers s6_addr32, FreeBSD has offered it to userland since 14.1 and
DragonFly offers it, both under __BSD_VISIBLE.  NetBSD and OpenBSD keep it
under _KERNEL, so a userland compile there gets

	error: 'const struct in6_addr' has no member named 's6_addr32'

in every one of the eighty-odd places NetworkManager uses it - the first is
src/libnm-glib-aux/nm-inet-utils.c:167.

All four BSDs spell the union member the same way, so the name is given once
in the header every internal source reaches through nm-default-std.h, rather
than each use being rewritten.  The guard leaves alone the systems that
already have it.

--- src/libnm-std-aux/nm-std-aux.h.orig
+++ src/libnm-std-aux/nm-std-aux.h
@@ -11,7 +11,30 @@
 #include <stdio.h>
 #include <errno.h>
 #include <stddef.h>
+#include <netinet/in.h>
 
+/*
+ * s6_addr32 is not portable.  glibc offers it, FreeBSD has offered it to
+ * userland since 14.1 and DragonFly offers it, both under __BSD_VISIBLE, but
+ * NetBSD and OpenBSD keep it under _KERNEL:
+ *
+ *	#define s6_addr   __u6_addr.__u6_addr8
+ *	#ifdef _KERNEL
+ *	#define s6_addr32 __u6_addr.__u6_addr32
+ *
+ * so a userland compile there gets
+ *
+ *	error: 'const struct in6_addr' has no member named 's6_addr32'
+ *
+ * in every one of the eighty-odd places NetworkManager uses it.  All four
+ * BSDs spell the union member the same way, so the name is given here once
+ * rather than each use being rewritten.  The guard leaves the systems that
+ * already have it alone.
+ */
+#ifndef s6_addr32
+#define s6_addr32 __u6_addr.__u6_addr32
+#endif
+
 /*****************************************************************************/
 
 #define _nm_packed             __attribute__((__packed__))
