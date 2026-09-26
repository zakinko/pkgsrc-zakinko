$NetBSD$

Stop this header from needing Linux's.

It pulled in <linux/if_packet.h>, but nothing here needs it: the address below
is n-dhcp4's own type, deliberately wider than sockaddr_ll so an Infiniband
hardware address fits.  __be16 came from the same place and is only a spelling
for a 16-bit field that happens to be stored big-endian.

The protocol number that goes in that field is named here for the same reason:
it is ETH_P_IP on Linux and ETHERTYPE_IP elsewhere, and 0x0800 in the standard
both of them are spelling.  Since the address is n-dhcp4's, so is the number.

--- src/n-dhcp4/src/util/packet.h.orig
+++ src/n-dhcp4/src/util/packet.h
@@ -6,20 +6,38 @@
 
 #include <c-stdaux.h>
 #include <inttypes.h>
-#include <linux/if_packet.h>
 #include <netinet/in.h>
 #include <stdlib.h>
 #include <unistd.h>
 
 /*
+ * This header used to pull in <linux/if_packet.h>, but nothing here needs it:
+ * the address below is our own type, not the kernel's, and it is deliberately
+ * not sockaddr_ll.  Dropping the include is what lets the rest of this file be
+ * read on a system that has no AF_PACKET at all.
+ *
+ * __be16 comes from the same place and is likewise only a spelling - it is a
+ * 16-bit field that happens to be stored big-endian - so it is spelled with a
+ * plain type here.
+ */
+
+/*
  * `struct sockaddr_ll` is too small to fit the Infiniband hardware address.
  * Introduce `struct packet_sockaddr_ll` which is the same as the original,
  * except the `sl_addr` field is extended to fit all the supported hardware
  * addresses.
  */
+/*
+ * The protocol number that goes in sll_protocol below.  It is ETH_P_IP on
+ * Linux and ETHERTYPE_IP everywhere else, and 0x0800 in the standard that
+ * both of them are spelling.  Since the address this sits in is our own type
+ * rather than the kernel's, the number is ours to name too.
+ */
+#define PACKET_PROTOCOL_IP (0x0800)
+
 struct packet_sockaddr_ll {
         unsigned short  sll_family;
-        __be16          sll_protocol;
+        uint16_t        sll_protocol;  /* big-endian on the wire */
         int             sll_ifindex;
         unsigned short  sll_hatype;
         unsigned char   sll_pkttype;
