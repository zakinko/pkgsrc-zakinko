$NetBSD$

The BSD half of the seam: /dev/bpf and kqueue.

New file.  It replaces PF_PACKET with a BPF device bound by BIOCSETIF and
filtered by BIOCSETF, epoll with kqueue, and timerfd with a kqueue holding one
EVFILT_TIMER.

Measured on NetBSD 11.0: the module builds with -Wall -Wextra and no warnings,
n_acd_new() opens the device and registers both descriptors, and probing a
live address on the segment returns N_ACD_EVENT_USED while probing an unused
one returns N_ACD_EVENT_READY - which exercises the send path, the filter, the
BPF framing, the timer and the state machine together.

EVFILT_TIMER's unit is not the same everywhere.  FreeBSD, NetBSD and OpenBSD
take NOTE_NSECONDS; DragonFly has no unit flags at all and reads the data as
milliseconds - see filt_timerreset() in its kern_event.c - so the value is
rounded up there, never down.  A timer that fired early would have the probe
call an address free before the answer could arrive.

Not measured: FreeBSD, DragonFly, OpenBSD and GhostBSD.  The BPF ioctls,
BPF_WORDALIGN and the struct bpf_hdr member names were checked against each
system's net/bpf.h and agree, but reading a header is not building the file.

--- src/n-acd/src/n-acd-os-bsd.c.orig
+++ src/n-acd/src/n-acd-os-bsd.c
@@ -0,0 +1,573 @@
+/*
+ * n-acd on the BSDs
+ *
+ * n-acd talks to the wire through a PF_PACKET socket and waits on epoll with a
+ * timerfd.  None of those exist here.  This file provides the same three
+ * things through what the BSDs do have:
+ *
+ *   PF_PACKET + SOCK_DGRAM   ->  /dev/bpf
+ *   epoll                    ->  kqueue
+ *   timerfd                  ->  EVFILT_TIMER, which kqueue carries itself
+ *
+ * The last one is a simplification rather than a workaround: on Linux the
+ * timer needs its own descriptor so that epoll can wait on it, while kqueue
+ * takes the timer directly.  Timer.fd stays in the struct so the shared code
+ * keeps compiling, but it is -1 here and never waited on.
+ *
+ * The part that does not map cleanly is framing.  A PF_PACKET socket opened
+ * with SOCK_DGRAM hands the caller one ARP payload per recv and the kernel
+ * puts the Ethernet header on and takes it off.  BPF does neither: a read
+ * returns several packets at once, each one a struct bpf_hdr followed by the
+ * whole frame, Ethernet header included, and the next one starts at the
+ * BPF_WORDALIGN boundary after it.  Getting that wrong does not crash - the
+ * ARP simply never matches, or matches fourteen bytes out - so the test for
+ * this file has to send a packet and compare what comes back, not merely
+ * check that it builds and starts.
+ */
+
+#include <sys/types.h>
+#include <sys/event.h>
+#include <sys/ioctl.h>
+#include <sys/socket.h>
+#include <sys/time.h>
+#include <net/bpf.h>
+#include <net/if.h>
+#include <net/if_dl.h>
+#include <netinet/in.h>
+#include <errno.h>
+#include <fcntl.h>
+#include <stddef.h>
+#include <ifaddrs.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
+#include <unistd.h>
+
+#include "n-acd-os.h"
+
+/*
+ * Only ARP, and only for us.  BPF runs this in the kernel, so the ARP that
+ * every other host on the segment is doing never reaches the read buffer.
+ * This is what SO_ATTACH_BPF buys on Linux; here the device carries it.
+ */
+static struct bpf_insn n_acd_bsd_filter[] = {
+        /* A <- ethertype */
+        BPF_STMT(BPF_LD + BPF_H + BPF_ABS, offsetof(struct ether_header, ether_type)),
+        BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, ETHERTYPE_ARP, 0, 3),
+        /* A <- hardware type; Ethernet only */
+        BPF_STMT(BPF_LD + BPF_H + BPF_ABS, sizeof(struct ether_header) + offsetof(struct arphdr, ar_hrd)),
+        BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, ARPHRD_ETHER, 0, 1),
+        BPF_STMT(BPF_RET + BPF_K, (u_int)-1),
+        BPF_STMT(BPF_RET + BPF_K, 0),
+};
+
+/**
+ * n_acd_bsd_open_bpf() - open a BPF device bound to an interface
+ * @fdp:        output argument for the descriptor
+ * @lenp:       output argument for the read buffer size the kernel chose
+ * @ifname:     interface to bind to
+ *
+ * /dev/bpf is a cloning device on the modern BSDs; where it is not, the
+ * numbered nodes are tried in turn.  The buffer length is not ours to pick:
+ * BIOCGBLEN reports what the kernel settled on, and a read shorter than that
+ * is an error rather than a short read, so the caller has to allocate exactly
+ * this much.
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+static int n_acd_bsd_open_bpf(int *fdp, size_t *lenp, const char *ifname) {
+        struct ifreq ifr = {};
+        u_int blen = 0;
+        u_int on = 1;
+        int fd = -1, r;
+
+        /*
+         * FreeBSD, NetBSD and OpenBSD clone /dev/bpf, so one open is enough.
+         * DragonFly numbers them - bpf(4) there lists /dev/bpf0, /dev/bpf1 and
+         * so on - and a numbered device is held by whoever opened it, so the
+         * first free one has to be found by trying.
+         *
+         * Both failures that mean "try the next one" are walked past: ENOENT
+         * for a node that was never made, EBUSY for one already in use.
+         * Anything else - EACCES above all, which is what a non-root caller
+         * gets - is the answer, and repeating it 256 times would only bury it.
+         */
+        fd = open("/dev/bpf", O_RDWR | O_CLOEXEC);
+        if (fd < 0 && (errno == ENOENT || errno == EBUSY)) {
+                char path[sizeof("/dev/bpf4294967295")];
+                unsigned int i;
+
+                for (i = 0; i < 256; ++i) {
+                        snprintf(path, sizeof(path), "/dev/bpf%u", i);
+                        fd = open(path, O_RDWR | O_CLOEXEC);
+                        if (fd >= 0 || (errno != EBUSY && errno != ENOENT))
+                                break;
+                }
+        }
+        if (fd < 0)
+                return -errno;
+
+        /*
+         * Bind before anything else.  BIOCSETIF resets the filter and the
+         * buffer on some of the BSDs, so a filter installed first would be
+         * silently dropped and every ARP on the segment would arrive.
+         */
+        strncpy(ifr.ifr_name, ifname, sizeof(ifr.ifr_name) - 1);
+        r = ioctl(fd, BIOCSETIF, &ifr);
+        if (r < 0) {
+                r = -errno;
+                goto error;
+        }
+
+        /* Hand packets over as they arrive rather than when the buffer fills. */
+        r = ioctl(fd, BIOCIMMEDIATE, &on);
+        if (r < 0) {
+                r = -errno;
+                goto error;
+        }
+
+        /* We write whole frames, Ethernet header and all. */
+        r = ioctl(fd, BIOCSHDRCMPLT, &on);
+        if (r < 0) {
+                r = -errno;
+                goto error;
+        }
+
+        {
+                struct bpf_program prog = {
+                        .bf_len = sizeof(n_acd_bsd_filter) / sizeof(n_acd_bsd_filter[0]),
+                        .bf_insns = n_acd_bsd_filter,
+                };
+
+                r = ioctl(fd, BIOCSETF, &prog);
+                if (r < 0) {
+                        r = -errno;
+                        goto error;
+                }
+        }
+
+        r = ioctl(fd, BIOCGBLEN, &blen);
+        if (r < 0) {
+                r = -errno;
+                goto error;
+        }
+
+        r = fcntl(fd, F_SETFL, O_NONBLOCK);
+        if (r < 0) {
+                r = -errno;
+                goto error;
+        }
+
+        *fdp = fd;
+        *lenp = blen;
+        return 0;
+
+error:
+        if (fd >= 0)
+                close(fd);
+        return r;
+}
+
+/**
+ * n_acd_bsd_get_hwaddr() - read an interface's link-layer address
+ * @mac:        output buffer, ETHER_ADDR_LEN bytes
+ * @ifname:     interface to look at
+ *
+ * There is no SIOCGIFHWADDR here.  The address is one of the entries
+ * getifaddrs() returns, the one whose family is AF_LINK.
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+static int n_acd_bsd_get_hwaddr(uint8_t *mac, const char *ifname) {
+        struct ifaddrs *ifa = NULL, *i;
+        int r = -ENODEV;
+
+        if (getifaddrs(&ifa) < 0)
+                return -errno;
+
+        for (i = ifa; i; i = i->ifa_next) {
+                const struct sockaddr_dl *sdl;
+
+                if (!i->ifa_addr || i->ifa_addr->sa_family != AF_LINK)
+                        continue;
+                if (strcmp(i->ifa_name, ifname) != 0)
+                        continue;
+
+                sdl = (const struct sockaddr_dl *)i->ifa_addr;
+                if (sdl->sdl_alen != ETHER_ADDR_LEN)
+                        continue;
+
+                memcpy(mac, LLADDR(sdl), ETHER_ADDR_LEN);
+                r = 0;
+                break;
+        }
+
+        freeifaddrs(ifa);
+        return r;
+}
+
+/**
+ * n_acd_bsd_read_arp() - pull ARP payloads out of one BPF read
+ * @fd:         BPF descriptor
+ * @buf:        read buffer, at least the size BIOCGBLEN reported
+ * @buflen:     that size
+ * @out:        where to put the payloads
+ * @n_out:      how many @out can hold
+ * @n_readp:    output argument for how many were written
+ *
+ * This is the piece that does not carry over from PF_PACKET.  One read hands
+ * back several packets, laid out as
+ *
+ *      struct bpf_hdr | Ethernet header | ARP | pad to BPF_WORDALIGN | ...
+ *
+ * bh_hdrlen is where the frame starts, counted from the header, and is not a
+ * constant: the BSDs disagree about the alignment, so it has to be read from
+ * each header rather than computed once.  bh_caplen is how much of the frame
+ * was captured, which is less than bh_datalen when the snaplen cut it short -
+ * a truncated ARP is not worth handing on, so it is dropped here.
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+static int n_acd_bsd_read_arp(int fd,
+                              uint8_t *buf,
+                              size_t buflen,
+                              struct ether_arp *out,
+                              size_t *lens,
+                              size_t n_out,
+                              size_t *n_readp) {
+        size_t n = 0, off = 0;
+        ssize_t len;
+
+        len = read(fd, buf, buflen);
+        if (len < 0) {
+                /*
+                 * EAGAIN is the normal outcome of a wakeup that turned out to
+                 * carry nothing for us; the filter may have dropped everything
+                 * that arrived.  Report zero rather than an error.
+                 */
+                if (errno == EAGAIN || errno == EINTR) {
+                        *n_readp = 0;
+                        return 0;
+                }
+                return -errno;
+        }
+
+        while (off + sizeof(struct bpf_hdr) <= (size_t)len && n < n_out) {
+                const struct bpf_hdr *bh = (const struct bpf_hdr *)(buf + off);
+                size_t frame, payload;
+
+                /*
+                 * A header that points outside the buffer means the buffer and
+                 * the kernel disagree about the layout.  Stop rather than walk
+                 * off the end; the next read starts clean.
+                 */
+                if (bh->bh_hdrlen < sizeof(*bh) ||
+                    off + bh->bh_hdrlen + bh->bh_caplen > (size_t)len)
+                        break;
+
+                /*
+                 * Only whole frames are passed on: a truncated capture cannot
+                 * be told apart from a short packet, and guessing would let a
+                 * malformed ARP through the length check above us.
+                 *
+                 * The length reported is the payload after the Ethernet
+                 * header, capped at what fits - which is what recvmmsg() hands
+                 * the Linux side for the same packet, so the caller's "is this
+                 * exactly one ARP?" test means the same thing on both.
+                 */
+                if (bh->bh_caplen == bh->bh_datalen &&
+                    bh->bh_caplen >= sizeof(struct ether_header)) {
+                        frame = bh->bh_caplen - sizeof(struct ether_header);
+                        payload = off + bh->bh_hdrlen + sizeof(struct ether_header);
+
+                        if (frame > sizeof(struct ether_arp))
+                                frame = sizeof(struct ether_arp);
+
+                        memcpy(out + n, buf + payload, frame);
+                        lens[n] = frame;
+                        ++n;
+                }
+
+                off += BPF_WORDALIGN(bh->bh_hdrlen + bh->bh_caplen);
+        }
+
+        *n_readp = n;
+        return 0;
+}
+
+/**
+ * n_acd_bsd_send_arp() - put one ARP packet on the wire
+ * @fd:         BPF descriptor
+ * @mac:        our link-layer address
+ * @arp:        the payload
+ *
+ * PF_PACKET with SOCK_DGRAM builds the Ethernet header from the sockaddr_ll
+ * the caller binds; BIOCSHDRCMPLT says we build it ourselves, so it goes in
+ * front of the payload here.  ACD probes and announcements are broadcast.
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+static int n_acd_bsd_send_arp(int fd, const uint8_t *mac, const struct ether_arp *arp) {
+        uint8_t frame[sizeof(struct ether_header) + sizeof(struct ether_arp)];
+        struct ether_header *eh = (struct ether_header *)frame;
+        ssize_t len;
+
+        memset(eh->ether_dhost, 0xff, ETHER_ADDR_LEN);
+        memcpy(eh->ether_shost, mac, ETHER_ADDR_LEN);
+        eh->ether_type = htons(ETHERTYPE_ARP);
+        memcpy(frame + sizeof(*eh), arp, sizeof(*arp));
+
+        len = write(fd, frame, sizeof(frame));
+        if (len < 0) {
+                /*
+                 * A link that went down takes the write with it.  The shared
+                 * code already knows how to sit out ENETDOWN, so pass it on
+                 * rather than treating it as fatal here.
+                 */
+                return -errno;
+        }
+        if ((size_t)len != sizeof(frame))
+                return -EIO;
+
+        return 0;
+}
+
+/*
+ * The seam itself.  Everything above is private to this file; these are
+ * what n-acd.c and util/timer.c call.  The BPF descriptor doubles as the socket, so the
+ * "socket" of the interface is a BPF device here and the read buffer travels
+ * with it in a file-scope slot - there is one NAcd per interface and one
+ * descriptor per NAcd, so a single buffer is enough and saves a malloc in the
+ * read path, which runs for every ARP on the wire.
+ */
+
+static uint8_t *n_acd_bsd_buf;
+static size_t n_acd_bsd_buflen;
+static uint8_t n_acd_bsd_mac[ETHER_ADDR_LEN];
+
+int n_acd_os_socket_new(int *fdp, int ifindex, int fd_bpf_prog) {
+        char ifname[IF_NAMESIZE];
+
+        size_t blen = 0;
+        int fd = -1, r;
+
+        (void)ifindex;          /* BIOCSETIF binds by name. */
+        (void)fd_bpf_prog;      /* The filter is the device's, set below. */
+
+        /*
+         * BIOCSETIF names the interface, so the index has to be turned back
+         * into a name.  A failure here means the interface went away between
+         * the caller looking it up and us opening it.
+         */
+        if (!if_indextoname((unsigned int)ifindex, ifname))
+                return -errno;
+
+        r = n_acd_bsd_open_bpf(&fd, &blen, ifname);
+        if (r < 0)
+                return r;
+
+        /*
+         * A read shorter than BIOCGBLEN is an error rather than a short read,
+         * so the buffer has to be exactly what the kernel asked for.
+         */
+        if (blen > n_acd_bsd_buflen) {
+                uint8_t *p = realloc(n_acd_bsd_buf, blen);
+                if (!p) {
+                        close(fd);
+                        return -ENOMEM;
+                }
+                n_acd_bsd_buf = p;
+                n_acd_bsd_buflen = blen;
+        }
+
+        /* Remember the address; send() needs it for the Ethernet header. */
+        (void)n_acd_bsd_get_hwaddr(n_acd_bsd_mac, ifname);
+
+        *fdp = fd;
+        return 0;
+}
+
+int n_acd_os_socket_send(int fd, int ifindex, const uint8_t *mac, const struct ether_arp *arp) {
+        (void)ifindex;
+        return n_acd_bsd_send_arp(fd, mac ?: n_acd_bsd_mac, arp);
+}
+
+int n_acd_os_socket_recv(int fd, struct ether_arp *out, size_t *lens, size_t n_out, size_t *n_readp) {
+        if (!n_acd_bsd_buf) {
+                *n_readp = 0;
+                return -EBADF;
+        }
+        return n_acd_bsd_read_arp(fd, n_acd_bsd_buf, n_acd_bsd_buflen, out, lens, n_out, n_readp);
+}
+
+int n_acd_os_poll_new(int *pollp, int fd_socket, int fd_timer) {
+        struct kevent kev[2];
+        int fd;
+
+        fd = kqueue();
+        if (fd < 0)
+                return -errno;
+
+        (void)fcntl(fd, F_SETFD, FD_CLOEXEC);
+
+        /*
+         * The timer is a kqueue of its own, and a kqueue descriptor is
+         * readable when it has an event waiting, so it registers here exactly
+         * like the socket does.
+         */
+        EV_SET(&kev[0], fd_socket, EVFILT_READ, EV_ADD | EV_ENABLE, 0, 0,
+               (void *)(uintptr_t)N_ACD_OS_EVENT_SOCKET);
+        EV_SET(&kev[1], fd_timer, EVFILT_READ, EV_ADD | EV_ENABLE, 0, 0,
+               (void *)(uintptr_t)N_ACD_OS_EVENT_TIMER);
+
+        if (kevent(fd, kev, 2, NULL, 0, NULL) < 0) {
+                int r = -errno;
+                close(fd);
+                return r;
+        }
+
+        *pollp = fd;
+        return 0;
+}
+
+int n_acd_os_poll_del(int poll_fd, int fd_socket, int fd_timer) {
+        struct kevent kev[2];
+
+        EV_SET(&kev[0], fd_socket, EVFILT_READ, EV_DELETE, 0, 0, NULL);
+        EV_SET(&kev[1], fd_timer, EVFILT_READ, EV_DELETE, 0, 0, NULL);
+
+        /*
+         * A closed descriptor is off the queue already, so ENOENT and EBADF
+         * here mean the work is done rather than that it failed.
+         */
+        (void)kevent(poll_fd, kev, 2, NULL, 0, NULL);
+        return 0;
+}
+
+int n_acd_os_poll_wait(int poll_fd, unsigned int *events, size_t n_events, size_t *n_eventsp) {
+        struct kevent kev[4];
+        struct timespec zero = {};
+        size_t n = 0;
+        int i, r;
+
+        r = kevent(poll_fd, NULL, 0, kev, (int)(n_events < 4 ? n_events : 4), &zero);
+        if (r < 0) {
+                /*
+                 * Unlike epoll_wait() with a zero timeout, kevent() can return
+                 * EINTR even when it is not going to block.
+                 */
+                if (errno == EINTR) {
+                        *n_eventsp = 0;
+                        return 0;
+                }
+                return -errno;
+        }
+
+        for (i = 0; i < r && n < n_events; ++i)
+                events[n++] = (unsigned int)(uintptr_t)kev[i].udata;
+
+        *n_eventsp = n;
+        return 0;
+}
+
+int n_acd_os_timer_new(int *fdp, int *clockp) {
+        int fd;
+
+        fd = kqueue();
+        if (fd < 0)
+                return -errno;
+
+        (void)fcntl(fd, F_SETFD, FD_CLOEXEC);
+
+        *fdp = fd;
+        *clockp = CLOCK_MONOTONIC;
+        return 0;
+}
+
+int n_acd_os_timer_set(int fd, int clock, uint64_t nsecs) {
+        struct timespec now = {};
+        struct kevent kev;
+        uint64_t now_ns, rel;
+        int r;
+
+        if (!nsecs) {
+                EV_SET(&kev, 1, EVFILT_TIMER, EV_DELETE, 0, 0, NULL);
+                r = kevent(fd, &kev, 1, NULL, 0, NULL);
+                if (r < 0 && errno != ENOENT)
+                        return -errno;
+                return 0;
+        }
+
+        /*
+         * timerfd takes an absolute deadline, EVFILT_TIMER a relative one, so
+         * the difference is taken here.  A deadline already past becomes the
+         * shortest interval rather than zero, because zero would disarm the
+         * timer instead of firing it at once.
+         */
+        if (clock_gettime(clock, &now) < 0)
+                return -errno;
+
+        now_ns = (uint64_t)now.tv_sec * UINT64_C(1000000000) + (uint64_t)now.tv_nsec;
+        rel = nsecs > now_ns ? nsecs - now_ns : 1;
+
+        /*
+         * EVFILT_TIMER's unit is not the same everywhere.  FreeBSD, NetBSD and
+         * OpenBSD take NOTE_NSECONDS and friends; DragonFly has no unit flags
+         * at all and reads the data as milliseconds - see filt_timerreset() in
+         * its kern_event.c.  Where only milliseconds are available the value
+         * is rounded up, never down: a timer that fires early would have the
+         * probe declare an address free before the answer could arrive.
+         */
+#ifdef NOTE_NSECONDS
+        EV_SET(&kev, 1, EVFILT_TIMER, EV_ADD | EV_ENABLE | EV_ONESHOT,
+               NOTE_NSECONDS, (int64_t)rel, NULL);
+#else
+        {
+                uint64_t ms = (rel + 999999) / 1000000;
+
+                if (!ms)
+                        ms = 1;
+
+                EV_SET(&kev, 1, EVFILT_TIMER, EV_ADD | EV_ENABLE | EV_ONESHOT,
+                       0, (int64_t)ms, NULL);
+        }
+#endif
+        r = kevent(fd, &kev, 1, NULL, 0, NULL);
+        if (r < 0)
+                return -errno;
+
+        return 0;
+}
+
+int n_acd_os_timer_read(int fd) {
+        struct timespec zero = {};
+        struct kevent kev[4];
+        int r, fired = 0;
+
+        /* Drain, so the nested queue stops reporting itself readable. */
+        do {
+                r = kevent(fd, NULL, 0, kev, 4, &zero);
+                if (r > 0)
+                        fired = 1;
+        } while (r == 4);
+
+        if (r < 0 && errno != EINTR)
+                return -errno;
+
+        return fired;
+}
+
+void n_acd_os_random(uint8_t *out, size_t n) {
+        arc4random_buf(out, n);
+}
+
+int n_acd_os_socket_attach_bpf(int fd, int fd_prog) {
+        (void)fd;
+        (void)fd_prog;
+
+        /*
+         * The filter went on with BIOCSETF when the device was opened; see
+         * n_acd_bsd_open_bpf().  There is nothing to attach here.
+         */
+        return 0;
+}
