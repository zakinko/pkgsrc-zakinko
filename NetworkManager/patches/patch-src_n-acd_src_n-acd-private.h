$NetBSD$

Pull in the portability seam, for ETH_ALEN.

ETH_ALEN is the Linux spelling of what the BSDs call ETHER_ADDR_LEN.  Both are
six; only the name differs, so n-acd-os.h spells it once and the users are left
alone.  n-acd-bpf-fallback.c reaches this header without going through n-acd.c,
so the include belongs here rather than there.

--- src/n-acd/src/n-acd-private.h.orig
+++ src/n-acd/src/n-acd-private.h
@@ -5,10 +5,10 @@
 #include <c-stdaux.h>
 #include <errno.h>
 #include <inttypes.h>
-#include <netinet/if_ether.h>
 #include <netinet/in.h>
 #include <stdbool.h>
 #include <stdlib.h>
+#include "n-acd-os.h"
 #include "util/timer.h"
 #include "n-acd.h"
 
@@ -64,7 +64,7 @@
 struct NAcd {
         unsigned long n_refs;
         unsigned int seed;
-        int fd_epoll;
+        int fd_poll;
         int fd_socket;
         CRBTree ip_tree;
         CList event_list;
@@ -85,7 +85,7 @@
 
 #define N_ACD_NULL(_x) {                                                        \
                 .n_refs = 1,                                                    \
-                .fd_epoll = -1,                                                 \
+                .fd_poll = -1,                                                 \
                 .fd_socket = -1,                                                \
                 .ip_tree = C_RBTREE_INIT,                                       \
                 .event_list = C_LIST_INIT((_x).event_list),                     \
