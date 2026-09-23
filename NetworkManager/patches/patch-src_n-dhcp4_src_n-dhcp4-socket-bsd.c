$NetBSD$

The BSD half of the socket layer.

New file.  A BPF device instead of AF_PACKET, BIOCSETF instead of
SO_ATTACH_FILTER, IP_RECVDSTADDR instead of IP_PKTINFO.

The filter needed more than renaming.  AF_PACKET/SOCK_DGRAM strips the link
header, so the Linux filter reads a packet that starts at the IP header; a BPF
device does not, so every offset moves past the Ethernet header and an
ethertype check is added, because binding the socket to ETH_P_IP used to
provide it.  Not all four addressing modes move the same way: BPF_ABS, BPF_MSH
and BPF_IND are positions and gain the fourteen bytes, but BPF_LEN is the
length of the whole frame, so the constant it is compared against gains them
instead.  Treating them alike would leave the length check short by exactly
that much, and short in the permissive direction.

That was measured rather than reasoned about.  NetBSD's libpcap exports
bpf_filter(), which is the same interpreter the kernel runs, so both filters
were put through it against the same packets: a valid reply, a wrong port, a
BOOTREQUEST, a bad magic cookie, a non-UDP packet, a fragment, a short packet
and one with options.  They agree on all eight, and the BSD one additionally
drops a frame whose ethertype is not IPv4.

A filter cannot be attached to a UDP socket at all here.  What the Linux one
checked, apart from the ports that bind() and connect() already settle, was the
magic cookie - which the message parser checks anyway - and the op field, which
nothing else checked.  That one is done explicitly when the datagram arrives.

n_dhcp4_s_socket_packet_new() returns -1 rather than a descriptor: a BPF device
must be bound to an interface before it can be written to, and that function is
not told which one.  The send path opens it.  NetworkManager does not build the
server, so this is here to keep the file whole rather than because it runs.

--- src/n-dhcp4/src/n-dhcp4-socket-bsd.c.orig
+++ src/n-dhcp4/src/n-dhcp4-socket-bsd.c
@@ -0,0 +1,591 @@
+/*
+ * DHCP specific low-level socket helpers - the BSDs
+ *
+ * Three things differ from the Linux file, and each is the reason a
+ * conditional would not have been enough:
+ *
+ *  - The raw path is a BPF device, not AF_PACKET.  It is bound with BIOCSETIF
+ *    while being opened, and it hands over whole Ethernet frames rather than
+ *    starting at the IP header.  Every offset in the packet filter therefore
+ *    moves by the length of that header, and an ethertype check has to be
+ *    added, because AF_PACKET let the kernel pick IP packets by binding the
+ *    socket to ETH_P_IP.
+ *
+ *  - A filter cannot be attached to a UDP socket at all.  Linux does it with
+ *    SO_ATTACH_FILTER as a cheap first pass; here the checks it performs are
+ *    left to the code that parses the message, which has to do them anyway.
+ *    One of them was only in the filter, so it is done explicitly below.
+ *
+ *  - Which address a packet was addressed to comes back as IP_RECVDSTADDR,
+ *    a bare struct in_addr, rather than IP_PKTINFO's struct in_pktinfo.
+ */
+
+#include <c-stdaux.h>
+#include <errno.h>
+#include <fcntl.h>
+#include <net/bpf.h>
+#include <net/if.h>
+#include <netinet/in.h>
+#include <netinet/in_systm.h>
+#include <netinet/ip.h>
+#include <netinet/udp.h>
+#include <stddef.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <stdint.h>
+#include <string.h>
+#include <sys/event.h>
+#include <sys/ioctl.h>
+#include <time.h>
+#include <sys/socket.h>
+#include <sys/types.h>
+#include "n-dhcp4-private.h"
+#include "util/packet.h"
+#include "util/socket.h"
+
+#ifdef __NetBSD__
+#  include <net/if_ether.h>
+#else
+#  include <net/ethernet.h>
+#endif
+
+/*
+ * A BPF device delivers whole frames, so every offset into the packet is
+ * further along by the Ethernet header.  Naming it makes the filters below
+ * readable as "the Linux filter, plus E".
+ */
+#define E (14)
+
+/*
+ * BPF_LEN is the one place where E is added to the other side of the
+ * comparison rather than to an offset: it yields the length of the whole
+ * frame, which includes the header, so the constant it is measured against
+ * has to grow instead.  Treating all four addressing modes alike would leave
+ * the length check short by exactly those fourteen bytes - and short in the
+ * permissive direction, which is the quiet kind of wrong.
+ */
+
+/**
+ * n_dhcp4_bsd_open_bpf() - open a BPF device bound to an interface
+ * @fdp:                return argument for the descriptor
+ * @ifindex:            interface to bind to
+ * @insns:              filter program, already in frame-relative offsets
+ * @n_insns:            length of @insns
+ *
+ * FreeBSD, NetBSD and OpenBSD clone /dev/bpf, so one open is enough.
+ * DragonFly numbers them and a numbered device is held by whoever opened it,
+ * so the first free one has to be found by trying.  ENOENT and EBUSY both mean
+ * "try the next"; anything else - EACCES above all, which is what a non-root
+ * caller gets - is the answer.
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+static int n_dhcp4_bsd_open_bpf(int *fdp,
+                                int ifindex,
+                                struct bpf_insn *insns,
+                                size_t n_insns) {
+        char ifname[IF_NAMESIZE];
+        struct ifreq ifr = {};
+        struct bpf_program prog = {};
+        u_int on = 1;
+        int fd, r;
+
+        if (!if_indextoname((unsigned int)ifindex, ifname))
+                return -errno;
+
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
+         * dropped without a word and every packet on the segment would arrive.
+         */
+        strncpy(ifr.ifr_name, ifname, sizeof(ifr.ifr_name) - 1);
+        r = ioctl(fd, BIOCSETIF, &ifr);
+        if (r < 0)
+                goto error;
+
+        /* Hand packets over as they arrive rather than when the buffer fills. */
+        r = ioctl(fd, BIOCIMMEDIATE, &on);
+        if (r < 0)
+                goto error;
+
+        /* We write whole frames, Ethernet header and all. */
+        r = ioctl(fd, BIOCSHDRCMPLT, &on);
+        if (r < 0)
+                goto error;
+
+        if (n_insns) {
+                prog.bf_len = (u_int)n_insns;
+                prog.bf_insns = insns;
+
+                r = ioctl(fd, BIOCSETF, &prog);
+                if (r < 0)
+                        goto error;
+        }
+
+        r = fcntl(fd, F_SETFL, O_NONBLOCK);
+        if (r < 0)
+                goto error;
+
+        *fdp = fd;
+        return 0;
+
+error:
+        r = -errno;
+        close(fd);
+        return r;
+}
+
+/**
+ * n_dhcp4_c_socket_packet_new() - create a new DHCP4 client packet socket
+ * @sockfdp:            return argument for the new socket
+ * @ifindex:            interface index to bind to
+ *
+ * Only unfragmented DHCP packets from a server to a client on the given
+ * interface are returned.  The filter is the Linux one with every offset moved
+ * past the Ethernet header, plus the ethertype check that binding the socket
+ * to ETH_P_IP used to provide.
+ *
+ * Return: 0 on success, or a negative error code on failure.
+ */
+int n_dhcp4_c_socket_packet_new(int *sockfdp, int ifindex) {
+        struct bpf_insn filter[] = {
+                /*
+                 * Ethernet
+                 *
+                 * AF_PACKET was bound to ETH_P_IP and let the kernel choose;
+                 * a BPF device hands over everything on the wire.
+                 */
+                BPF_STMT(BPF_LD + BPF_H + BPF_ABS, 12),                                                         /* A <- ethertype */
+                BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, ETHERTYPE_IP, 1, 0),                                        /* IPv4 ? */
+                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
+
+                /*
+                 * IP
+                 *
+                 * Check
+                 *  - UDP
+                 *  - Unfragmented
+                 *  - Large enough to fit the DHCP header
+                 *
+                 *  Leave X the size of the IP header, for future indirect reads.
+                 */
+                BPF_STMT(BPF_LD + BPF_B + BPF_ABS, E + offsetof(struct ip, ip_p)),                              /* A <- IP protocol */
+                BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, IPPROTO_UDP, 1, 0),                                         /* IP protocol == UDP ? */
+                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
+
+                BPF_STMT(BPF_LD + BPF_H + BPF_ABS, E + offsetof(struct ip, ip_off)),                            /* A <- Flags + Fragment offset */
+                BPF_STMT(BPF_ALU + BPF_AND + BPF_K, IP_MF | IP_OFFMASK),                                        /* A <- A & (IP_MF | IP_OFFMASK) */
+                BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, 0, 1, 0),                                                   /* fragmented packet ? */
+                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
+
+                BPF_STMT(BPF_LDX + BPF_B + BPF_MSH, E),                                                         /* X <- IP header length */
+                BPF_STMT(BPF_LD + BPF_W + BPF_LEN, 0),                                                          /* A <- frame length */
+                BPF_STMT(BPF_ALU + BPF_SUB + BPF_X, 0),                                                         /* A -= X */
+                BPF_JUMP(BPF_JMP + BPF_JGE + BPF_K,
+                         E + sizeof(struct udphdr) + sizeof(NDhcp4Message), 1, 0),                              /* packet >= DHCPPacket ? */
+                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
+
+                /*
+                 * UDP
+                 *
+                 * Check
+                 *  - DHCP client port
+                 *
+                 * Leave X the size of IP and UDP headers, for future indirect reads.
+                 */
+                BPF_STMT(BPF_LD + BPF_H + BPF_IND, E + offsetof(struct udphdr, uh_dport)),                      /* A <- UDP destination port */
+                BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, N_DHCP4_NETWORK_CLIENT_PORT, 1, 0),                         /* UDP destination port == DHCP client port ? */
+                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
+
+                BPF_STMT(BPF_LD + BPF_W + BPF_K, sizeof(struct udphdr)),                                        /* A <- size of UDP header */
+                BPF_STMT(BPF_ALU + BPF_ADD + BPF_X, 0),                                                         /* A += X */
+                BPF_STMT(BPF_MISC + BPF_TAX, 0),                                                                /* X <- A */
+
+                /*
+                 * DHCP
+                 *
+                 * Check
+                 *  - BOOTREPLY (from server to client)
+                 *  - DHCP magic cookie
+                 */
+                BPF_STMT(BPF_LD + BPF_B + BPF_IND, E + offsetof(NDhcp4Header, op)),                             /* A <- DHCP op */
+                BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, N_DHCP4_OP_BOOTREPLY, 1, 0),                                /* op == BOOTREPLY ? */
+                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
+
+                BPF_STMT(BPF_LD + BPF_W + BPF_IND, E + offsetof(NDhcp4Message, magic)),                         /* A <- DHCP magic cookie */
+                BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, N_DHCP4_MESSAGE_MAGIC, 1, 0),                               /* cookie == DHCP magic cookie ? */
+                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
+
+                BPF_STMT(BPF_RET + BPF_K, 65535),                                                               /* return all */
+        };
+
+        return n_dhcp4_bsd_open_bpf(sockfdp, ifindex, filter,
+                                    sizeof(filter) / sizeof(filter[0]));
+}
+
+/**
+ * n_dhcp4_c_socket_udp_new() - create a new DHCP4 client UDP socket
+ *
+ * The Linux file attaches a filter here as a first pass.  A UDP socket cannot
+ * carry one on the BSDs, and it would add little: the socket is bound to the
+ * client's own address and connected to the server, so the kernel already
+ * delivers only what the filter's port checks would have kept.  What the
+ * filter also checked - that the message is a BOOTREPLY and carries the DHCP
+ * magic - the message parser checks for the magic, and the op is checked
+ * explicitly when the datagram is received.  See n_dhcp4_socket_udp_recv().
+ *
+ * Return: 0 on success, or a negative error code on failure.
+ */
+int n_dhcp4_c_socket_udp_new(int *sockfdp,
+                             int ifindex,
+                             const struct in_addr *client_addr,
+                             const struct in_addr *server_addr,
+                             uint8_t dscp) {
+        _c_cleanup_(c_closep) int sockfd = -1;
+        struct sockaddr_in saddr = {
+                .sin_family = AF_INET,
+                .sin_addr = *client_addr,
+                .sin_port = htons(N_DHCP4_NETWORK_CLIENT_PORT),
+        };
+        struct sockaddr_in daddr = {
+                .sin_family = AF_INET,
+                .sin_addr = *server_addr,
+                .sin_port = htons(N_DHCP4_NETWORK_SERVER_PORT),
+        };
+        int r, on = 1;
+        int tos = dscp << 2;
+
+        sockfd = socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC | SOCK_NONBLOCK, 0);
+        if (sockfd < 0)
+                return -errno;
+
+        r = setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on));
+        if (r < 0)
+                return -errno;
+
+        r = socket_bind_if(sockfd, ifindex);
+        if (r)
+                return r;
+
+        r = setsockopt(sockfd, SOL_SOCKET, SO_BROADCAST, &on, sizeof(on));
+        if (r < 0)
+                return -errno;
+
+        r = setsockopt(sockfd, IPPROTO_IP, IP_TOS, &tos, sizeof(tos));
+        if (r < 0)
+                return -errno;
+
+        r = bind(sockfd, (struct sockaddr *)&saddr, sizeof(saddr));
+        if (r < 0)
+                return -errno;
+
+        r = connect(sockfd, (struct sockaddr *)&daddr, sizeof(daddr));
+        if (r < 0)
+                return -errno;
+
+        *sockfdp = sockfd;
+        sockfd = -1;
+        return 0;
+}
+
+/**
+ * n_dhcp4_s_socket_packet_new() - create a new DHCP4 server packet socket
+ *
+ * The server sends to clients that have no address yet, so it needs the raw
+ * path, but it never reads from it.  On Linux an unbound AF_PACKET socket is
+ * enough; a BPF device has to be bound to an interface before it can be
+ * written to, and there is none to name here.  The descriptor is therefore
+ * opened lazily - see n_dhcp4_s_socket_packet_send(), which knows the
+ * interface.
+ *
+ * Return: 0 on success, or a negative error code on failure.
+ */
+int n_dhcp4_s_socket_packet_new(int *sockfdp) {
+        /*
+         * -1 is not an error here: the send path opens the device once it
+         * knows which interface to bind it to.  NetworkManager does not build
+         * the server, so this is here to keep the file whole rather than
+         * because it runs.
+         */
+        *sockfdp = -1;
+        return 0;
+}
+
+/**
+ * n_dhcp4_s_socket_udp_new() - create a new DHCP4 server UDP socket
+ *
+ * IP_RECVDSTADDR is the BSD spelling of what Linux gets from IP_PKTINFO: the
+ * address the packet was addressed to, which the server needs in order to tell
+ * a directed request from a broadcast one.
+ *
+ * Return: 0 on success, or a negative error code on failure.
+ */
+int n_dhcp4_s_socket_udp_new(int *sockfdp, int ifindex) {
+        _c_cleanup_(c_closep) int sockfd = -1;
+        struct sockaddr_in addr = {
+                .sin_family = AF_INET,
+                .sin_addr = { INADDR_ANY },
+                .sin_port = htons(N_DHCP4_NETWORK_SERVER_PORT),
+        };
+        int r, tos = IPTOS_CLASS_CS6, on = 1;
+
+        sockfd = socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC | SOCK_NONBLOCK, 0);
+        if (sockfd < 0)
+                return -errno;
+
+        r = socket_bind_if(sockfd, ifindex);
+        if (r)
+                return r;
+
+        r = setsockopt(sockfd, SOL_SOCKET, SO_BROADCAST, &on, sizeof(on));
+        if (r < 0)
+                return -errno;
+
+        r = setsockopt(sockfd, IPPROTO_IP, IP_TOS, &tos, sizeof(tos));
+        if (r < 0)
+                return -errno;
+
+        r = setsockopt(sockfd, IPPROTO_IP, IP_RECVDSTADDR, &on, sizeof(on));
+        if (r < 0)
+                return -errno;
+
+        r = bind(sockfd, (struct sockaddr *)&addr, sizeof(addr));
+        if (r < 0)
+                return -errno;
+
+        *sockfdp = sockfd;
+        sockfd = -1;
+        return 0;
+}
+
+/**
+ * n_dhcp4_socket_udp_recv() - receive a datagram and the address it was sent to
+ *
+ * The op field is checked here because the filter that checked it on Linux
+ * cannot be attached to a UDP socket.  The magic cookie is checked by
+ * n_dhcp4_incoming_new(), so it is not repeated.
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+int n_dhcp4_socket_udp_recv(int sockfd,
+                            uint8_t *buf,
+                            size_t n_buf,
+                            NDhcp4Incoming **messagep,
+                            struct in_addr *dest_addr) {
+        _c_cleanup_(n_dhcp4_incoming_freep) NDhcp4Incoming *message = NULL;
+        struct iovec iov = {
+                .iov_base = buf,
+                .iov_len = n_buf,
+        };
+        uint8_t cmsgbuf[CMSG_SPACE(sizeof(struct in_addr))];
+        struct msghdr msg = {
+                .msg_iov = &iov,
+                .msg_iovlen = 1,
+                .msg_control = cmsgbuf,
+                .msg_controllen = sizeof(cmsgbuf),
+        };
+        struct cmsghdr *cmsg;
+        ssize_t len;
+        int r;
+
+        len = recvmsg(sockfd, &msg, 0);
+        if (len < 0) {
+                if (errno == ENETDOWN)
+                        return N_DHCP4_E_DOWN;
+                else if (errno == EAGAIN)
+                        return N_DHCP4_E_AGAIN;
+                else
+                        return -errno;
+        } else if (len == 0 || (size_t)len > n_buf) {
+                return N_DHCP4_E_MALFORMED;
+        }
+
+        /*
+         * Linux drops anything that is not a reply in the socket filter.  There
+         * is no filter here, so a datagram that reached this port carrying a
+         * request is dropped now rather than handed to the state machine.
+         */
+        if ((size_t)len < sizeof(NDhcp4Header) ||
+            ((const NDhcp4Header *)buf)->op != N_DHCP4_OP_BOOTREPLY)
+                return N_DHCP4_E_MALFORMED;
+
+        r = n_dhcp4_incoming_new(&message, buf, len);
+        if (r)
+                return r;
+
+        if (dest_addr) {
+                *dest_addr = (struct in_addr){};
+
+                for (cmsg = CMSG_FIRSTHDR(&msg); cmsg; cmsg = CMSG_NXTHDR(&msg, cmsg)) {
+                        if (cmsg->cmsg_level != IPPROTO_IP ||
+                            cmsg->cmsg_type != IP_RECVDSTADDR ||
+                            cmsg->cmsg_len != CMSG_LEN(sizeof(struct in_addr)))
+                                continue;
+
+                        memcpy(dest_addr, CMSG_DATA(cmsg), sizeof(*dest_addr));
+                        break;
+                }
+        }
+
+        *messagep = message;
+        message = NULL;
+        return 0;
+}
+
+/**
+ * n_dhcp4_os_random() - seed material for the jitter
+ *
+ * arc4random_buf(3) is both simpler and better than reading the auxiliary
+ * vector, and it cannot fail.
+ */
+void n_dhcp4_os_random(uint8_t *out, size_t n) {
+        arc4random_buf(out, n);
+}
+
+int n_dhcp4_os_poll_new(int *fdp) {
+        int fd;
+
+        fd = kqueue();
+        if (fd < 0)
+                return -errno;
+
+        (void)fcntl(fd, F_SETFD, FD_CLOEXEC);
+
+        *fdp = fd;
+        return 0;
+}
+
+int n_dhcp4_os_poll_add(int pollfd, int fd, unsigned int id) {
+        struct kevent kev;
+
+        EV_SET(&kev, fd, EVFILT_READ, EV_ADD | EV_ENABLE, 0, 0,
+               (void *)(uintptr_t)id);
+
+        if (kevent(pollfd, &kev, 1, NULL, 0, NULL) < 0)
+                return -errno;
+
+        return 0;
+}
+
+int n_dhcp4_os_poll_del(int pollfd, int fd) {
+        struct kevent kev;
+
+        EV_SET(&kev, fd, EVFILT_READ, EV_DELETE, 0, 0, NULL);
+
+        /*
+         * A closed descriptor is off the queue already, so ENOENT and EBADF
+         * here mean the work is done rather than that it failed.
+         */
+        (void)kevent(pollfd, &kev, 1, NULL, 0, NULL);
+        return 0;
+}
+
+int n_dhcp4_os_poll_wait(int pollfd, unsigned int *ids, size_t n_ids, size_t *n_outp) {
+        struct timespec zero = {};
+        struct kevent events[8];
+        size_t n = n_ids < 8 ? n_ids : 8;
+        int i, r;
+
+        r = kevent(pollfd, NULL, 0, events, (int)n, &zero);
+        if (r < 0) {
+                /*
+                 * Unlike epoll_wait() with a zero timeout, kevent() can return
+                 * EINTR even when it was never going to block.
+                 */
+                if (errno == EINTR) {
+                        *n_outp = 0;
+                        return 0;
+                }
+                return -errno;
+        }
+
+        for (i = 0; i < r; ++i)
+                ids[i] = (unsigned int)(uintptr_t)events[i].udata;
+
+        *n_outp = (size_t)r;
+        return 0;
+}
+
+int n_dhcp4_os_timer_new(int *fdp) {
+        int fd;
+
+        fd = kqueue();
+        if (fd < 0)
+                return -errno;
+
+        (void)fcntl(fd, F_SETFD, FD_CLOEXEC);
+
+        *fdp = fd;
+        return 0;
+}
+
+int n_dhcp4_os_timer_set(int fd, uint64_t nsecs) {
+        struct kevent kev;
+
+        if (!nsecs) {
+                EV_SET(&kev, 1, EVFILT_TIMER, EV_DELETE, 0, 0, NULL);
+                if (kevent(fd, &kev, 1, NULL, 0, NULL) < 0 && errno != ENOENT)
+                        return -errno;
+                return 0;
+        }
+
+        /*
+         * EVFILT_TIMER's unit is not the same everywhere.  FreeBSD, NetBSD and
+         * OpenBSD take NOTE_NSECONDS; DragonFly has no unit flags at all and
+         * reads the data as milliseconds - see filt_timerreset() in its
+         * kern_event.c.  Where only milliseconds are available the value is
+         * rounded up, never down: a timer that fired early would have the
+         * client act on a deadline that has not arrived.
+         */
+#ifdef NOTE_NSECONDS
+        EV_SET(&kev, 1, EVFILT_TIMER, EV_ADD | EV_ENABLE | EV_ONESHOT,
+               NOTE_NSECONDS, (int64_t)nsecs, NULL);
+#else
+        {
+                uint64_t ms = (nsecs + 999999) / 1000000;
+
+                if (!ms)
+                        ms = 1;
+
+                EV_SET(&kev, 1, EVFILT_TIMER, EV_ADD | EV_ENABLE | EV_ONESHOT,
+                       0, (int64_t)ms, NULL);
+        }
+#endif
+        if (kevent(fd, &kev, 1, NULL, 0, NULL) < 0)
+                return -errno;
+
+        return 0;
+}
+
+int n_dhcp4_os_timer_read(int fd) {
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
