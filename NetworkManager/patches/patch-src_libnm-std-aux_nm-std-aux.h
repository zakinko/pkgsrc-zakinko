$NetBSD$

Give the BSDs the names NetworkManager expects from glibc.

s6_addr32.  glibc offers it, FreeBSD has offered it to userland since 14.1
and DragonFly offers it, both under __BSD_VISIBLE.  NetBSD and OpenBSD keep
it under _KERNEL, so a userland compile there gets

	error: 'const struct in6_addr' has no member named 's6_addr32'

in every one of the eighty-odd places it is used - the first is
src/libnm-glib-aux/nm-inet-utils.c:167.  All four BSDs spell the union member
the same way, so the name is given once here.

Twelve Linux errno values.  NM_ERRNO_IS_DISCONNECT() lists ENONET, and the
bundled systemd code tests for and returns the others, so the next stop is

	nm-io-utils.h:104: error: 'ENONET' undeclared

They are given values of 10000 plus Linux's own number.  That is this port's
choice; nothing specifies it.  The largest errno is 98 on NetBSD, 97 on
FreeBSD, 95 on OpenBSD and 99 on DragonFly, so a test for one of them never
matches anything the kernel returns, and a value handed back internally
still compares equal to itself.

Both go in the header every internal source reaches through
nm-default-std.h, and each is guarded so that systems which already have the
name are left alone.

--- src/libnm-std-aux/nm-std-aux.h.orig
+++ src/libnm-std-aux/nm-std-aux.h
@@ -11,6 +11,80 @@
 #include <stdio.h>
 #include <errno.h>
 #include <stddef.h>
+#include <netinet/in.h>
+
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
+/*
+ * Linux errno values that the BSDs do not have.  NetworkManager tests for
+ * them (NM_ERRNO_IS_DISCONNECT() lists ENONET) and the bundled systemd code
+ * both tests for and returns some of them, so a BSD compile stops at
+ *
+ *	nm-io-utils.h:104: error: 'ENONET' undeclared
+ *
+ * The values are this port's choice, not anything a standard gives: 10000
+ * plus Linux's own number.  The largest errno is 98 on NetBSD, 97 on FreeBSD,
+ * 95 on OpenBSD and 99 on DragonFly, so none of these can equal an errno the
+ * kernel returns.  A test for one of them therefore never matches, which is
+ * right - the condition cannot arise there - and a value handed back
+ * internally still compares equal to itself.
+ */
+#ifndef ECHRNG
+#define ECHRNG (10000 + 44)
+#endif
+#ifndef EXFULL
+#define EXFULL (10000 + 54)
+#endif
+#ifndef ENOANO
+#define ENOANO (10000 + 55)
+#endif
+#ifndef ENONET
+#define ENONET (10000 + 64)
+#endif
+#ifndef ENOPKG
+#define ENOPKG (10000 + 65)
+#endif
+#ifndef EBADFD
+#define EBADFD (10000 + 77)
+#endif
+#ifndef ESTRPIPE
+#define ESTRPIPE (10000 + 86)
+#endif
+#ifndef EUCLEAN
+#define EUCLEAN (10000 + 117)
+#endif
+#ifndef EREMOTEIO
+#define EREMOTEIO (10000 + 121)
+#endif
+#ifndef ENOMEDIUM
+#define ENOMEDIUM (10000 + 123)
+#endif
+#ifndef EMEDIUMTYPE
+#define EMEDIUMTYPE (10000 + 124)
+#endif
+#ifndef ENOKEY
+#define ENOKEY (10000 + 126)
+#endif
 
 /*****************************************************************************/
 
