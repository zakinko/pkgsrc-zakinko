$NetBSD$

Get the jitter's seed from the system rather than from AT_RANDOM.

getauxval(AT_RANDOM) is a Linux facility; the BSDs have arc4random(3), which is
both simpler and better.  Which one is used is the seam's business.

The unused events parameter is dropped from
n_dhcp4_client_probe_dispatch_io(); see the change to n-dhcp4-client.c.

--- src/n-dhcp4/src/n-dhcp4-c-probe.c.orig
+++ src/n-dhcp4/src/n-dhcp4-c-probe.c
@@ -15,7 +15,6 @@
 #include <stdbool.h>
 #include <stdlib.h>
 #include <string.h>
-#include <sys/auxv.h>
 #include "n-dhcp4.h"
 #include "n-dhcp4-private.h"
 
@@ -328,7 +327,7 @@
         };
         CSipHash hash = C_SIPHASH_NULL;
         unsigned short int seed16v[3];
-        const uint8_t *p;
+        uint8_t seed[16];
         uint64_t u64;
 
         /*
@@ -339,8 +338,8 @@
          * but only meant to improve network utilization during bursts. The
          * random source is thus negligible. However, we want, under all
          * circumstances, avoid two instances running with the same seed. Thus
-         * we source the seed from AT_RANDOM, which grants us a per-process
-         * unique seed. We then add the current time to make sure consequetive
+         * we source the seed from the system - AT_RANDOM on Linux, which
+         * grants us a per-process unique seed, arc4random(3) elsewhere. We then add the current time to make sure consequetive
          * instances use different seeds (to avoid clashes if processes are
          * duplicated, or similar), and lastly we add the config memory address
          * to avoid clashes of multiple parallel instances.
@@ -352,15 +351,14 @@
          * network and the chance of packets being dropped (and thus triggering
          * timeouts and resends).
          *
-         * We hash everything through SipHash, to avoid exposing AT_RANDOM and
+         * We hash everything through SipHash, to avoid exposing the seed and
          * other sources to the network. We use a static salt to distinguish it
          * from other implementations using the same random source.
          */
         c_siphash_init(&hash, hash_seed);
 
-        p = (const uint8_t *)getauxval(AT_RANDOM);
-        if (p)
-                c_siphash_append(&hash, p, 16);
+        n_dhcp4_os_random(seed, sizeof(seed));
+        c_siphash_append(&hash, seed, sizeof(seed));
 
         u64 = n_dhcp4_gettime(CLOCK_MONOTONIC);
         c_siphash_append(&hash, (const uint8_t *)&u64, sizeof(u64));
@@ -442,7 +440,7 @@
                                       client->config,
                                       probe->config,
                                       &client->log_queue,
-                                      active ? client->fd_epoll : -1);
+                                      active ? client->fd_poll : -1);
         if (r)
                 return r;
 
@@ -1245,7 +1243,7 @@
 /**
  * n_dhcp4_client_probe_dispatch_connection() - XXX
  */
-int n_dhcp4_client_probe_dispatch_io(NDhcp4ClientProbe *probe, uint32_t events) {
+int n_dhcp4_client_probe_dispatch_io(NDhcp4ClientProbe *probe) {
         _c_cleanup_(n_dhcp4_incoming_freep) NDhcp4Incoming *message = NULL;
         uint8_t type;
         int r;
