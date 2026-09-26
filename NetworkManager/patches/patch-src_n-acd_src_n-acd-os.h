$NetBSD$

The portability seam between n-acd and the kernel.

New file.  It declares the eleven calls that n-acd.c and util/timer.c make into
the kernel, so that each platform's answer lives in one file of its own rather
than in conditionals spread through n-acd.c.  A reader of either
implementation sees one system's idea of networking written plainly.

--- src/n-acd/src/n-acd-os.h.orig
+++ src/n-acd/src/n-acd-os.h
@@ -0,0 +1,159 @@
+#pragma once
+
+/*
+ * The seam between n-acd and the kernel
+ *
+ * n-acd reaches the kernel in six places: it opens a packet socket, sends an
+ * ARP, reads a batch of them, creates a poller, moves a timer, and waits.
+ * Everything else - the state machine, the probe scheduling, the rbtree of
+ * addresses - is portable and is not touched.
+ *
+ * Those six are gathered here so that the port is a second file rather than
+ * conditionals threaded through n-acd.c.  n-acd-os-linux.c keeps the existing
+ * PF_PACKET, epoll and timerfd code; n-acd-os-bsd.c does the same work with
+ * /dev/bpf and kqueue.  A reader of either file sees one platform's idea of
+ * networking written plainly, which is easier to check than a file where two
+ * are interleaved.
+ *
+ * The batch size is the caller's: on Linux it becomes the recvmmsg array, on
+ * the BSDs the number of packets taken from one BPF read.  Both return the
+ * count actually filled, which may be zero when a wakeup turns out to carry
+ * nothing - a filtered packet on the BSDs, a spurious readiness on Linux.
+ */
+
+/*
+ * <netinet/if_ether.h> declares struct arphdr with struct sockaddr and struct
+ * in_addr members, and on FreeBSD, GhostBSD and OpenBSD it does not pull in
+ * the headers that define them.  NetBSD's does, which is why this was not
+ * seen there:
+ *
+ *	/usr/include/net/if_arp.h:89:18: error: field has incomplete type
+ *	'struct sockaddr'
+ *
+ * OpenBSD needs one more.  Its <netinet/if_ether.h> declares struct ether_arp
+ * with a struct arphdr member and does not define that either; on OpenBSD
+ * struct arphdr lives in <net/if_arp.h>, which the header does not pull in:
+ *
+ *	/usr/include/netinet/if_ether.h:154:17: error: field has incomplete type
+ *	'struct arphdr'
+ *
+ * So the prelude is included first, in the order the headers need.  Every
+ * other file in n-acd reaches <netinet/if_ether.h> through this header rather
+ * than including it itself, so the order is stated once.
+ */
+#include <sys/types.h>
+#include <sys/socket.h>
+#include <net/if_arp.h>
+#include <netinet/in.h>
+#include <netinet/if_ether.h>
+#include <stddef.h>
+#include <stdint.h>
+
+/*
+ * ETH_ALEN is <net/ethernet.h>'s spelling on Linux and ETHER_ADDR_LEN
+ * everywhere else.  Six is six; the name is the only difference, so it is
+ * spelled once here rather than at each of its uses.
+ */
+#ifndef ETH_ALEN
+#  define ETH_ALEN ETHER_ADDR_LEN
+#endif
+
+typedef struct NAcd NAcd;
+
+/* Which of the two sources woke the poller. */
+enum {
+        N_ACD_OS_EVENT_TIMER,
+        N_ACD_OS_EVENT_SOCKET,
+};
+
+/*
+ * Open the packet socket for @ifindex/@ifname and leave it ready to read.
+ *
+ * The index is what the caller has - NAcdConfig carries nothing else, and
+ * widening the public API for the sake of this port would reach every caller.
+ * PF_PACKET binds by index directly; BIOCSETIF wants a name, so the BSD side
+ * asks if_indextoname() for one and reports its failure as its own.
+ */
+int n_acd_os_socket_new(int *fdp, int ifindex, int fd_bpf_prog);
+
+/* Broadcast one ARP.  @mac is the sender's, already in the payload as well. */
+int n_acd_os_socket_send(int fd, int ifindex, const uint8_t *mac, const struct ether_arp *arp);
+
+/*
+ * Take up to @n_out packets.  @n_readp is set to how many were written, and
+ * zero is a normal answer.  Returns -ENETDOWN when the link went away, which
+ * the caller sits out rather than treating as fatal.
+ *
+ * @lens receives each packet's length on the wire, not the amount copied, so
+ * that a truncated ARP is still recognisable as the wrong length.  The caller
+ * checks it; the seam does not, because deciding what a valid packet is is the
+ * state machine's job on both platforms.
+ */
+int n_acd_os_socket_recv(int fd, struct ether_arp *out, size_t *lens, size_t n_out, size_t *n_readp);
+
+/*
+ * Create the poller with @fd_socket and @fd_timer registered on it, and undo
+ * that again.  Both descriptors stay the caller's to close; the poller only
+ * watches them.
+ *
+ * The timer is registered here rather than armed here, because the timer's own
+ * descriptor carries the deadline - see n_acd_os_timer_set() below.  The
+ * poller's job is only to say which of the two woke it.
+ */
+int n_acd_os_poll_new(int *pollp, int fd_socket, int fd_timer);
+int n_acd_os_poll_del(int poll_fd, int fd_socket, int fd_timer);
+
+/*
+ * Collect what is ready, without blocking.  @events is filled with
+ * N_ACD_OS_EVENT_* values and @n_eventsp with how many.
+ */
+int n_acd_os_poll_wait(int poll_fd, unsigned int *events, size_t n_events, size_t *n_eventsp);
+
+/*
+ * The timer is a descriptor on both platforms, which is what lets util/timer.c
+ * stay as it is: it holds one fd, arms it with an absolute deadline, and the
+ * poller waits on it like any other.
+ *
+ * On Linux that descriptor is a timerfd.  On the BSDs it is a second kqueue
+ * carrying one EVFILT_TIMER - a kqueue descriptor is itself pollable, and
+ * registering it in the outer kqueue with EVFILT_READ makes it readable when
+ * its timer fires.  Measured on NetBSD 11.0: the outer kevent() returns the
+ * nested queue, and reading that queue yields the timer event.
+ *
+ * @nsecs is absolute, on the clock the timer reports back through @clockp,
+ * and zero disarms.  The caller drains the descriptor after a firing.
+ *
+ * The clock itself is chosen per OS - Linux prefers CLOCK_BOOTTIME and falls
+ * back to CLOCK_MONOTONIC, the BSDs have only the latter - so the caller asks
+ * for one rather than naming it.
+ */
+int n_acd_os_timer_new(int *fdp, int *clockp);
+int n_acd_os_timer_set(int fd, int clock, uint64_t nsecs);
+/*
+ * Returns 1 if the timer had fired and was drained, 0 if it had not, and a
+ * negative errno otherwise.  The caller distinguishes the two: a spurious
+ * wakeup must not be reported upwards as a timeout.
+ */
+int n_acd_os_timer_read(int fd);
+
+/*
+ * Fill @n bytes of seed material for the probe jitter.
+ *
+ * Linux reads AT_RANDOM out of the auxiliary vector, which is what n-acd has
+ * always done; the BSDs have arc4random_buf(), which is both simpler and
+ * better.  Neither is allowed to fail: a zeroed buffer would make every host
+ * pick the same jitter, which is precisely what the jitter is for.  The caller
+ * hashes what comes back, so this is a seed rather than a key.
+ */
+void n_acd_os_random(uint8_t *out, size_t n);
+
+/*
+ * Attach a compiled packet filter to the socket, if there is one.
+ *
+ * Linux compiles the filter separately and hands the socket a descriptor
+ * afterwards, so this is where it lands.  The BSDs set their filter with
+ * BIOCSETF while the BPF device is being opened - there is no later moment to
+ * attach one, and no descriptor to attach - so the BSD side accepts the call
+ * and does nothing.  @fd_prog is negative when n-acd was built without eBPF.
+ */
+int n_acd_os_socket_attach_bpf(int fd, int fd_prog);
