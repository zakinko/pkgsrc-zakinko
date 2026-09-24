$NetBSD$

Spell the names that differ, once, and declare the seam.

ETH_ALEN, INFINIBAND_ALEN and ARPHRD_INFINIBAND are Linux's names for numbers
the standards fix at six, twenty and thirty-two.  Only the first has a name
elsewhere (ETHER_ADDR_LEN), so all three are spelled here rather than at each
of their uses.

CLOCK_BOOTTIME is different: it is not a spelling but a clock, monotonic but
still counting while the machine is suspended, and the BSDs have no equivalent.
The call sites name it in a dozen places and are left alone; it is defined here
as the nearest thing that exists.  What changes is that a lease's remaining
time is not counted down across a suspend, so the lease is renewed late rather
than early - the safe direction.

The seam itself is declared here too: the poller, the timer, the seed for the
jitter, and the one receive that reads ancillary data.  Linux reports which
address a packet was addressed to through IP_PKTINFO and the BSDs through
IP_RECVDSTADDR, but only the address is ever wanted, so struct in_pktinfo -
which only one of them has - does not appear in the interface.

--- src/n-dhcp4/src/n-dhcp4-private.h.orig
+++ src/n-dhcp4/src/n-dhcp4-private.h
@@ -7,6 +7,18 @@
 #include <endian.h>
 #include <inttypes.h>
 #include <limits.h>
+/*
+ * <netinet/ip.h> is the one include here that is not alphabetical.  On the
+ * BSDs it needs <netinet/in.h> for struct in_addr and <netinet/in_systm.h>
+ * for n_short and n_long, and does not pull either in itself:
+ *
+ *	/usr/include/netinet/ip.h:67:19: error: field has incomplete type
+ *	'struct in_addr'
+ *
+ * Linux's does, which is why the order did not matter there.
+ */
+#include <netinet/in.h>
+#include <netinet/in_systm.h>
 #include <netinet/ip.h>
 #include <stdbool.h>
 #include <stdlib.h>
@@ -27,6 +39,54 @@
 typedef struct NDhcp4SEventNode NDhcp4SEventNode;
 typedef struct NDhcp4LogQueue NDhcp4LogQueue;
 
+/*
+ * CLOCK_BOOTTIME is a Linux clock: monotonic, but it keeps counting while the
+ * machine is suspended.  The BSDs have no equivalent, so the call sites - which
+ * name it in a dozen places - are left alone and it is spelled here as the
+ * nearest thing that exists.  What changes is that a lease's remaining time is
+ * not counted down across a suspend; the lease is then renewed late rather
+ * than early, which is the safe direction.
+ */
+/*
+ * ETH_ALEN and INFINIBAND_ALEN are Linux's spellings for the length of a
+ * hardware address.  Six and twenty are what the standards say, and the BSDs
+ * name only the first of them (as ETHER_ADDR_LEN), so both are spelled once
+ * here rather than at each of their uses.
+ */
+/*
+ * htype in the DHCP header is an ARP hardware type: 1 for Ethernet, 32 for
+ * Infiniband, as the IANA registry has it.  ARPHRD_ETHER is 1 everywhere, but
+ * only Linux names the second, in <linux/if_arp.h>.
+ */
+#ifndef ARPHRD_INFINIBAND
+#  define ARPHRD_INFINIBAND (32)
+#endif
+
+#ifndef ETH_ALEN
+#  define ETH_ALEN (6)
+#endif
+#ifndef INFINIBAND_ALEN
+#  define INFINIBAND_ALEN (20)
+#endif
+
+#ifndef CLOCK_BOOTTIME
+#  define CLOCK_BOOTTIME CLOCK_MONOTONIC
+#endif
+
+/*
+ * Linux spells the DSCP class selectors IPTOS_CLASS_CSn; the BSDs spell the
+ * same values IPTOS_DSCP_CSn.  Both are (n << 5): CS0 is 0 and CS6 is 0xc0.
+ * NetBSD happens to have both, the other BSDs only the second, so the name
+ * the code uses is defined where it is missing rather than each use being
+ * written twice.
+ */
+#ifndef IPTOS_CLASS_CS0
+#  define IPTOS_CLASS_CS0 IPTOS_DSCP_CS0
+#endif
+#ifndef IPTOS_CLASS_CS6
+#  define IPTOS_CLASS_CS6 IPTOS_DSCP_CS6
+#endif
+
 /* specs */
 
 #define N_DHCP4_NETWORK_IP_MAXIMUM_HEADER_SIZE (60) /* See RFC791 */
@@ -327,7 +387,7 @@
         NDhcp4ClientProbeConfig *probe_config;
         NDhcp4LogQueue *log_queue;
 
-        int fd_epoll;
+        int fd_poll;
 
         unsigned int state;             /* current connection state */
         int fd_packet;                  /* packet socket */
@@ -353,7 +413,7 @@
 
         NDhcp4LogQueue log_queue;
 
-        int fd_epoll;
+        int fd_poll;
         int fd_timer;
 
         uint16_t mtu;
@@ -366,7 +426,7 @@
 #define N_DHCP4_CLIENT_NULL(_x) {                                               \
                 .n_refs = 1,                                                    \
                 .event_list = C_LIST_INIT((_x).event_list),                     \
-                .fd_epoll = -1,                                                 \
+                .fd_poll = -1,                                                 \
                 .fd_timer = -1,                                                 \
                 .log_queue = N_DHCP4_LOG_QUEUE_NULL_CLIENT(_x),                 \
         }
@@ -537,6 +597,53 @@
 /* sockets */
 
 int n_dhcp4_c_socket_packet_new(int *sockfdp, int ifindex);
+
+/*
+ * Receive one datagram, and optionally the address it was addressed to.  Only
+ * the address is wanted, which every system can report - Linux through
+ * IP_PKTINFO, the BSDs through IP_RECVDSTADDR - so the whole of Linux's
+ * struct in_pktinfo does not appear here.
+ */
+/*
+ * Fill @n bytes of seed material for the jitter.  Linux reads AT_RANDOM out of
+ * the auxiliary vector, which is what n-dhcp4 has always done; the BSDs have
+ * arc4random_buf().  Neither is allowed to fail: a zeroed seed would make
+ * every host pick the same jitter, which is what the jitter is for.
+ */
+void n_dhcp4_os_random(uint8_t *out, size_t n);
+
+/*
+ * The poller and the timer.
+ *
+ * Linux has epoll and timerfd; the BSDs have kqueue, and a timer that is a
+ * second kqueue carrying one EVFILT_TIMER - a kqueue descriptor is itself
+ * pollable, so registering it in the outer one makes it readable when its
+ * timer fires.  Either way what the rest of n-dhcp4 sees is one descriptor to
+ * hand to its caller and a tag saying which source woke it.
+ *
+ * Descriptors come and go here, unlike in n-acd: the packet socket is dropped
+ * once a lease is taken.  Hence add and del rather than one registration at
+ * creation.
+ *
+ * @nsecs is how long from now, not a point in time, and zero disarms - which
+ * is what the caller already computed, and what EVFILT_TIMER wants, so nobody
+ * has to convert.  n_dhcp4_os_timer_read() returns 1 if the timer had fired,
+ * 0 if it had not, and a negative errno otherwise; a spurious wakeup must not
+ * be reported upwards as a timeout.
+ */
+int n_dhcp4_os_poll_new(int *fdp);
+int n_dhcp4_os_poll_add(int pollfd, int fd, unsigned int id);
+int n_dhcp4_os_poll_del(int pollfd, int fd);
+int n_dhcp4_os_poll_wait(int pollfd, unsigned int *ids, size_t n_ids, size_t *n_outp);
+int n_dhcp4_os_timer_new(int *fdp);
+int n_dhcp4_os_timer_set(int fd, uint64_t nsecs);
+int n_dhcp4_os_timer_read(int fd);
+
+int n_dhcp4_socket_udp_recv(int sockfd,
+                            uint8_t *buf,
+                            size_t n_buf,
+                            NDhcp4Incoming **messagep,
+                            struct in_addr *dest_addr);
 int n_dhcp4_c_socket_udp_new(int *sockfdp,
                              int ifindex,
                              const struct in_addr *client_addr,
@@ -605,7 +712,7 @@
                               NDhcp4ClientConfig *client_config,
                               NDhcp4ClientProbeConfig *probe_config,
                               NDhcp4LogQueue *log_queue,
-                              int fd_epoll);
+                              int fd_poll);
 void n_dhcp4_c_connection_deinit(NDhcp4CConnection *connection);
 
 int n_dhcp4_c_connection_listen(NDhcp4CConnection *connection);
@@ -662,7 +769,7 @@
 int n_dhcp4_client_probe_raise(NDhcp4ClientProbe *probe, NDhcp4CEventNode **nodep, unsigned int event);
 void n_dhcp4_client_probe_get_timeout(NDhcp4ClientProbe *probe, uint64_t *timeoutp);
 int n_dhcp4_client_probe_dispatch_timer(NDhcp4ClientProbe *probe, uint64_t ns_now);
-int n_dhcp4_client_probe_dispatch_io(NDhcp4ClientProbe *probe, uint32_t events);
+int n_dhcp4_client_probe_dispatch_io(NDhcp4ClientProbe *probe);
 int n_dhcp4_client_probe_transition_select(NDhcp4ClientProbe *probe, NDhcp4Incoming *offer, uint64_t ns_now);
 int n_dhcp4_client_probe_transition_accept(NDhcp4ClientProbe *probe, NDhcp4Incoming *ack);
 int n_dhcp4_client_probe_transition_decline(NDhcp4ClientProbe *probe, NDhcp4Incoming *offer, const char *error, uint64_t ns_now);
