$NetBSD$

The Linux half of the seam: PF_PACKET, epoll and timerfd.

New file.  The code is the code that was in n-acd.c, moved rather than
rewritten, so that the Linux build keeps doing exactly what it did.

One thing did change.  Registering the timerfd used to be guarded by a
file-scope "static int registered", which is wrong as soon as a process holds
more than one NAcd: the second one would never have its timer added.  Folding
the registration into n_acd_os_poll_new(), where both descriptors are already
in hand, removes the need for the flag.

--- src/n-acd/src/n-acd-os-linux.c.orig
+++ src/n-acd/src/n-acd-os-linux.c
@@ -0,0 +1,259 @@
+/*
+ * n-acd on Linux
+ *
+ * This is the code that used to sit in n-acd.c, moved behind the seam in
+ * n-acd-os.h so that the BSD port can be a sibling file rather than a set of
+ * conditionals.  Nothing here is new; the socket options, the recvmmsg batch
+ * and the epoll registration are as they were.
+ */
+
+#include <linux/if_packet.h>
+#include <netinet/if_ether.h>
+#include <netinet/in.h>
+#include <sys/epoll.h>
+#include <sys/ioctl.h>
+#include <sys/socket.h>
+#include <sys/timerfd.h>
+#include <endian.h>
+#include <errno.h>
+#include <stddef.h>
+#include <string.h>
+#include <sys/auxv.h>
+#include <unistd.h>
+
+#include "n-acd-os.h"
+
+#ifndef SO_ATTACH_BPF
+#  define SO_ATTACH_BPF 50
+#endif
+
+int n_acd_os_socket_new(int *fdp, int ifindex, int fd_bpf_prog) {
+        const struct sockaddr_ll address = {
+                .sll_family = AF_PACKET,
+                .sll_protocol = htobe16(ETH_P_ARP),
+                .sll_ifindex = ifindex,
+                .sll_halen = ETH_ALEN,
+                .sll_addr = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff },
+        };
+        int r, s = -1;
+
+        s = socket(PF_PACKET, SOCK_DGRAM | SOCK_CLOEXEC | SOCK_NONBLOCK, 0);
+        if (s < 0) {
+                r = -errno;
+                goto error;
+        }
+
+        if (fd_bpf_prog >= 0) {
+                r = setsockopt(s, SOL_SOCKET, SO_ATTACH_BPF, &fd_bpf_prog, sizeof(fd_bpf_prog));
+                if (r < 0) {
+                        r = -errno;
+                        goto error;
+                }
+        }
+
+        r = bind(s, (const struct sockaddr *)&address, sizeof(address));
+        if (r < 0) {
+                r = -errno;
+                goto error;
+        }
+
+        *fdp = s;
+        return 0;
+
+error:
+        if (s >= 0)
+                close(s);
+        return r;
+}
+
+int n_acd_os_socket_send(int fd, int ifindex, const uint8_t *mac, const struct ether_arp *arp) {
+        struct sockaddr_ll address = {
+                .sll_family = AF_PACKET,
+                .sll_protocol = htobe16(ETH_P_ARP),
+                .sll_ifindex = ifindex,
+                .sll_halen = ETH_ALEN,
+                .sll_addr = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff },
+        };
+        ssize_t l;
+
+        /*
+         * The kernel builds the Ethernet header from sll_addr, so the sender's
+         * address is only in the payload here; the BSD side has to write it
+         * into the frame itself.
+         */
+        (void)mac;
+
+        l = sendto(fd, arp, sizeof(*arp), MSG_NOSIGNAL,
+                   (struct sockaddr *)&address, sizeof(address));
+        if (l < 0)
+                return -errno;
+        if ((size_t)l != sizeof(*arp))
+                return -EIO;
+
+        return 0;
+}
+
+int n_acd_os_socket_recv(int fd, struct ether_arp *out, size_t *lens, size_t n_out, size_t *n_readp) {
+        struct mmsghdr msgs[n_out];
+        struct iovec iovecs[n_out];
+        size_t i;
+        int n;
+
+        for (i = 0; i < n_out; ++i) {
+                iovecs[i].iov_base = out + i;
+                iovecs[i].iov_len = sizeof(out[i]);
+                msgs[i].msg_hdr = (struct msghdr){
+                        .msg_iov = iovecs + i,
+                        .msg_iovlen = 1,
+                };
+        }
+
+        n = recvmmsg(fd, msgs, n_out, 0, NULL);
+        if (n < 0) {
+                if (errno == EAGAIN || errno == EINTR) {
+                        *n_readp = 0;
+                        return 0;
+                }
+                return -errno;
+        }
+
+        for (i = 0; i < (size_t)n; ++i)
+                lens[i] = msgs[i].msg_len;
+
+        *n_readp = (size_t)n;
+        return 0;
+}
+
+int n_acd_os_poll_new(int *pollp, int fd_socket, int fd_timer) {
+        struct epoll_event eevent;
+        int fd, r;
+
+        fd = epoll_create1(EPOLL_CLOEXEC);
+        if (fd < 0)
+                return -errno;
+
+        eevent = (struct epoll_event){ .events = EPOLLIN, .data.u32 = N_ACD_OS_EVENT_TIMER };
+        r = epoll_ctl(fd, EPOLL_CTL_ADD, fd_timer, &eevent);
+        if (r < 0)
+                goto error;
+
+        eevent = (struct epoll_event){ .events = EPOLLIN, .data.u32 = N_ACD_OS_EVENT_SOCKET };
+        r = epoll_ctl(fd, EPOLL_CTL_ADD, fd_socket, &eevent);
+        if (r < 0)
+                goto error;
+
+        *pollp = fd;
+        return 0;
+
+error:
+        r = -errno;
+        close(fd);
+        return r;
+}
+
+int n_acd_os_poll_del(int poll_fd, int fd_socket, int fd_timer) {
+        /*
+         * A descriptor the caller already closed is off the set, so a failure
+         * here means there was nothing left to remove.
+         */
+        (void)epoll_ctl(poll_fd, EPOLL_CTL_DEL, fd_socket, NULL);
+        (void)epoll_ctl(poll_fd, EPOLL_CTL_DEL, fd_timer, NULL);
+        return 0;
+}
+
+int n_acd_os_poll_wait(int poll_fd, unsigned int *events, size_t n_events, size_t *n_eventsp) {
+        struct epoll_event eevents[n_events];
+        int i, n;
+
+        n = epoll_wait(poll_fd, eevents, (int)n_events, 0);
+        if (n < 0) {
+                /* Linux never returns EINTR when the timeout is zero. */
+                return -errno;
+        }
+
+        for (i = 0; i < n; ++i)
+                events[i] = eevents[i].data.u32;
+
+        *n_eventsp = (size_t)n;
+        return 0;
+}
+
+int n_acd_os_timer_new(int *fdp, int *clockp) {
+        int clock = CLOCK_BOOTTIME;
+        int fd;
+
+        fd = timerfd_create(clock, TFD_CLOEXEC | TFD_NONBLOCK);
+        if (fd < 0 && errno == EINVAL) {
+                clock = CLOCK_MONOTONIC;
+                fd = timerfd_create(clock, TFD_CLOEXEC | TFD_NONBLOCK);
+        }
+        if (fd < 0)
+                return -errno;
+
+        *fdp = fd;
+        *clockp = clock;
+        return 0;
+}
+
+int n_acd_os_timer_set(int fd, int clock, uint64_t nsecs) {
+        struct itimerspec spec = {};
+
+        (void)clock;            /* The clock was fixed when the fd was made. */
+
+        spec.it_value.tv_sec = nsecs / UINT64_C(1000000000);
+        spec.it_value.tv_nsec = nsecs % UINT64_C(1000000000);
+
+        if (timerfd_settime(fd, TFD_TIMER_ABSTIME, &spec, NULL) < 0)
+                return -errno;
+
+        return 0;
+}
+
+int n_acd_os_timer_read(int fd) {
+        uint64_t v;
+        ssize_t l;
+
+        l = read(fd, &v, sizeof(v));
+        if (l < 0) {
+                if (errno == EAGAIN)
+                        return 0;
+                if (errno == EINTR)
+                        return 0;
+                return -errno;
+        }
+
+        /*
+         * The kernel guarantees 8-byte reads and only returns data when a
+         * timer actually triggered; anything else means the descriptor is not
+         * what we think it is.
+         */
+        if (l != (ssize_t)sizeof(v) || v == 0)
+                return -EIO;
+
+        return 1;
+}
+
+void n_acd_os_random(uint8_t *out, size_t n) {
+        const uint8_t *p;
+
+        /*
+         * AT_RANDOM is 16 bytes the kernel put there at exec time.  It is
+         * absent only on kernels older than anything n-acd supports, and the
+         * clock the caller mixes in afterwards carries the rest.
+         */
+        p = (const uint8_t *)getauxval(AT_RANDOM);
+        if (p && n <= 16)
+                memcpy(out, p, n);
+        else
+                memset(out, 0, n);
+}
+
+int n_acd_os_socket_attach_bpf(int fd, int fd_prog) {
+        if (fd_prog < 0)
+                return 0;
+
+        if (setsockopt(fd, SOL_SOCKET, SO_ATTACH_BPF, &fd_prog, sizeof(fd_prog)) < 0)
+                return -errno;
+
+        return 0;
+}
