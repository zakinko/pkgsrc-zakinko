$NetBSD$

Reach <netinet/if_ether.h> through n-acd-os.h.

The include block here is alphabetical, so <netinet/if_ether.h> comes before
<netinet/in.h> and there is no <sys/socket.h> at all.  On FreeBSD, GhostBSD and
OpenBSD that header needs both, and on OpenBSD also <net/if_arp.h>, none of
which it pulls in itself:

	/usr/include/net/if_arp.h:89:18: error: field has incomplete type
	'struct sockaddr'

NetBSD's <netinet/if_ether.h> does pull them in, which is why this was not
seen there.  n-acd-os.h states the order once and every other file in n-acd
now reaches the header through it, so dropping the direct include here is
enough.

--- src/n-acd/src/n-acd-probe.c.orig
+++ src/n-acd/src/n-acd-probe.c
@@ -13,7 +13,6 @@
 #include <errno.h>
 #include <inttypes.h>
 #include <limits.h>
-#include <netinet/if_ether.h>
 #include <netinet/in.h>
 #include <stdio.h>
 #include <stdlib.h>
