$NetBSD$

Reach <netinet/ip.h> through n-dhcp4-private.h.

On the BSDs that header needs struct in_addr from <netinet/in.h> and n_short
and n_long from <netinet/in_systm.h>, and pulls in neither itself:

	/usr/include/netinet/ip.h:67:19: error: field has incomplete type
	'struct in_addr'

Linux's does, which is why the order did not matter there.  n-dhcp4-private.h
states it once and is included here anyway, so the direct include is dropped.

--- src/n-dhcp4/src/n-dhcp4-outgoing.c.orig
+++ src/n-dhcp4/src/n-dhcp4-outgoing.c
@@ -9,7 +9,6 @@
 #include <endian.h>
 #include <errno.h>
 #include <inttypes.h>
-#include <netinet/ip.h>
 #include <netinet/udp.h>
 #include <stdbool.h>
 #include <stddef.h>
