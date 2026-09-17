$NetBSD$

libndp is written against Linux headers.  Provide the BSD spellings.

FreeBSD ports carries the same fix (net/libndp,
files/patch-libndp_libndp.c) against this same 1.9 release; that is where
the FreeBSD half comes from, widened to DragonFly.

The NetBSD block was wrong in the first version of this patch and is
corrected here.  It said s6_addr32 was already available because

	grep -n s6_addr32 /usr/include/netinet6/in6.h
	135:#define s6_addr32 __u6_addr.__u6_addr32

found it.  The define exists, but it sits inside

	#ifdef _KERNEL	/* XXX nonstandard */

so user land never sees it, and the build failed with

	libndp.c:334:13: error: 'struct in6_addr' has no member named 's6_addr32'

Compiling a three-line program on NetBSD 11.0/amd64 shows the same, with
and without _XOPEN_SOURCE.  Finding the line and having the name visible
are two different things.

What NetBSD does already provide, and so is not redefined here, is
ND_RA_FLAG_HOME_AGENT (0x20).  What it lacks is net/ethernet.h (the
length lives in net/if_ether.h), ETH_ALEN, ND_OPT_PI_FLAG_RADDR and
SIOCGIFHWADDR.

The sendto() cast is from the FreeBSD patch: the fourth argument is a
struct sockaddr *, and these compilers make the bare &sin6 an error.

Not yet measured: whether SIOCGIFADDR returns the link-layer address on
NetBSD the way SIOCGIFMAC does on FreeBSD.  It compiles; the run has not
been made.  The address is properly taken from getifaddrs() with AF_LINK.

--- libndp/libndp.c.orig
+++ libndp/libndp.c
@@ -29,7 +29,11 @@
 #include <netinet/in.h>
 #include <netinet/icmp6.h>
 #include <arpa/inet.h>
+#ifdef __NetBSD__
+#include <net/if_ether.h>
+#else
 #include <net/ethernet.h>
+#endif
 #include <assert.h>
 #include <ndp.h>
 #include <net/if.h>
@@ -38,6 +42,28 @@
 #include "ndp_private.h"
 #include "list.h"
 
+#if defined(__FreeBSD__) || defined(__DragonFly__) || defined(__NetBSD__)
+/* s6_addr32 and friends are inside #ifdef _KERNEL on NetBSD and absent on
+ * FreeBSD; the union member names are the same on all three. */
+#define s6_addr8  __u6_addr.__u6_addr8
+#define s6_addr16 __u6_addr.__u6_addr16
+#define s6_addr32 __u6_addr.__u6_addr32
+#define ND_OPT_PI_FLAG_RADDR	0x20
+#define ifr_hwaddr		ifr_addr
+#endif
+
+#if defined(__FreeBSD__) || defined(__DragonFly__)
+#define SIOCGIFHWADDR		SIOCGIFMAC
+#define ND_RA_FLAG_HOME_AGENT	ND_RA_FLAG_HA
+#define ETH_ALEN		6
+#endif
+
+#ifdef __NetBSD__
+/* ND_RA_FLAG_HOME_AGENT is already defined here. */
+#define SIOCGIFHWADDR		SIOCGIFADDR
+#define ETH_ALEN		ETHER_ADDR_LEN
+#endif
+
 #define pr_err(args...) fprintf(stderr, ##args)
 
 /**
@@ -209,7 +235,8 @@
 	memcpy(&sin6.sin6_addr, addr, sizeof(sin6.sin6_addr));
 	sin6.sin6_scope_id = ifindex;
 resend:
-	ret = sendto(sockfd, buf, buflen, flags, &sin6, sizeof(sin6));
+	ret = sendto(sockfd, buf, buflen, flags, (struct sockaddr *)&sin6,
+		     sizeof(sin6));
 	if (ret == -1) {
 		switch(errno) {
 		case EINTR:
