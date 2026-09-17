$NetBSD$

libndp is written against Linux headers.  Provide the BSD spellings.

FreeBSD ports carries the same fix (net/libndp,
files/patch-libndp_libndp.c, maintainer arrowd@FreeBSD.org) against this
same 1.9 release.  That block is taken from there unchanged and widened
to DragonFly, which inherits the same headers.  Whether DragonFly really
has all of them is what the CI is for; if one is missing it says so.

NetBSD needs a different set, so it gets its own block.  Measured on
NetBSD 11.0/amd64:

  net/ethernet.h        does not exist; ETHER_ADDR_LEN is in net/if_ether.h
  ND_RA_FLAG_HOME_AGENT is already defined as 0x20, unlike FreeBSD
  s6_addr32             is already defined (netinet6/in6.h:135)
  ETH_ALEN              absent
  ND_OPT_PI_FLAG_RADDR  absent

so only the missing names are added and the header is swapped.  Taking
the FreeBSD block as well would redefine what NetBSD already has.

The sendto() cast is also from the FreeBSD patch: the fourth argument is
a struct sockaddr *, and passing &sin6 without a cast is an error rather
than a warning on the compilers these BSDs ship.

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
@@ -37,6 +41,25 @@
 
 #include "ndp_private.h"
 #include "list.h"
+
+#if defined(__FreeBSD__) || defined(__DragonFly__)
+#define s6_addr8  __u6_addr.__u6_addr8
+#define s6_addr16 __u6_addr.__u6_addr16
+#define s6_addr32 __u6_addr.__u6_addr32
+#define SIOCGIFHWADDR		SIOCGIFMAC
+#define ND_RA_FLAG_HOME_AGENT	ND_RA_FLAG_HA
+#define ND_OPT_PI_FLAG_RADDR	0x20
+#define ifr_hwaddr		ifr_addr
+#define ETH_ALEN		6
+#endif
+
+#ifdef __NetBSD__
+/* ND_RA_FLAG_HOME_AGENT and s6_addr32 are already provided. */
+#define ND_OPT_PI_FLAG_RADDR	0x20
+#define ETH_ALEN		ETHER_ADDR_LEN
+#define SIOCGIFHWADDR		SIOCGIFADDR
+#define ifr_hwaddr		ifr_addr
+#endif
 
 #define pr_err(args...) fprintf(stderr, ##args)
 
@@ -209,7 +232,8 @@
 	memcpy(&sin6.sin6_addr, addr, sizeof(sin6.sin6_addr));
 	sin6.sin6_scope_id = ifindex;
 resend:
-	ret = sendto(sockfd, buf, buflen, flags, &sin6, sizeof(sin6));
+	ret = sendto(sockfd, buf, buflen, flags, (struct sockaddr *)&sin6,
+		     sizeof(sin6));
 	if (ret == -1) {
 		switch(errno) {
 		case EINTR:
