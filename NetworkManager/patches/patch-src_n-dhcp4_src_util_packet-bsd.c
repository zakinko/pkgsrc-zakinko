$NetBSD$

The BSD half of the packet helpers.

New file.  A BPF write carries the whole Ethernet frame, so it is built here
and the sender's own address is looked up; a BPF read returns whole frames,
each behind a struct bpf_hdr, so there is nothing to peek at.

The IP header checksum is verified on receive, which the Linux file does not
do.  That is not an added check but one taken over: the packet never went
through the IP stack, so nobody else has looked at it.

Measured on NetBSD 11.0.  A frame written to a pipe comes back with the right
length, a broadcast destination, the interface's own address as the source,
ethertype IP, an IP header whose checksum recomputes to zero, the expected
ports and length, and the payload byte for byte.  Read back through the parser,
a truncated frame is skipped, the payload matches, the source address and port
are right, and a frame whose payload has been altered is dropped on the UDP
checksum - which is how one can tell the check runs rather than merely being
present.

--- src/n-dhcp4/src/util/packet-bsd.c.orig
+++ src/n-dhcp4/src/util/packet-bsd.c
@@ -0,0 +1,407 @@
+/*
+ * Packet Sockets - the BSDs
+ *
+ * Where Linux has AF_PACKET, the BSDs have a BPF device.  The two differ in
+ * more than spelling, which is why this is a file of its own rather than
+ * conditionals inside packet.c:
+ *
+ *  - AF_PACKET/SOCK_DGRAM hides the link header.  The kernel builds it on send
+ *    from the sockaddr_ll, and strips it on receive.  A BPF device does
+ *    neither: a write must carry the whole Ethernet frame, and a read returns
+ *    whole frames.
+ *
+ *  - A read from AF_PACKET returns one packet, so the code above it can peek
+ *    at the IP header, decide how long it is, and read the rest.  A read from
+ *    BPF returns a buffer of however many frames were waiting, each behind a
+ *    struct bpf_hdr, and it must be exactly the size the kernel asked for.
+ *    There is nothing to peek at - the packet is already here.
+ *
+ * Only the three entry points are shared with the Linux file.  The checksums
+ * live in packet.c and are used by both.
+ */
+
+#include <c-stdaux.h>
+#include <errno.h>
+#include <ifaddrs.h>
+#include <net/bpf.h>
+#include <net/if.h>
+#include <net/if_dl.h>
+#include <netinet/in.h>
+#include <netinet/in_systm.h>
+#include <netinet/ip.h>
+#include <netinet/udp.h>
+#include <stdbool.h>
+#include <stdlib.h>
+#include <string.h>
+#include <sys/ioctl.h>
+#include <sys/socket.h>
+#include <sys/types.h>
+#include <sys/uio.h>
+#include <unistd.h>
+#include "packet.h"
+
+/*
+ * struct ether_header, ETHER_ADDR_LEN and ETHERTYPE_IP.  <net/ethernet.h> is
+ * FreeBSD's and DragonFly's spelling and does not exist on NetBSD or OpenBSD;
+ * <netinet/if_ether.h> is on all four.  It needs the sockaddr and in_addr
+ * definitions first, and on OpenBSD struct arphdr from <net/if_arp.h>, none
+ * of which it pulls in itself.
+ */
+#include <sys/types.h>
+#include <sys/socket.h>
+#include <net/if_arp.h>
+#include <netinet/in.h>
+#include <netinet/if_ether.h>
+
+/*
+ * ETHER_ADDR_LEN is the spelling everywhere but Linux, and ETHERTYPE_IP is in
+ * the same header.  Both are fixed by the protocol; naming them here keeps the
+ * code below reading as plainly as the Linux file does.
+ */
+#define PACKET_ETHER_HDR_LEN (14U)
+#define PACKET_IP_HDR_LEN    (20U)
+#define PACKET_UDP_HDR_LEN   (8U)
+
+/**
+ * packet_bsd_hwaddr() - fetch an interface's hardware address by index
+ * @ifindex:            interface to look at
+ * @mac:                output, ETHER_ADDR_LEN bytes
+ *
+ * A BPF write carries the whole Ethernet frame, so the sender's own address
+ * has to be filled in.  AF_PACKET never needed this: the kernel knew which
+ * interface the socket was bound to and wrote the source address itself.
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+static int packet_bsd_hwaddr(int ifindex, uint8_t *mac) {
+        char ifname[IF_NAMESIZE];
+        struct ifaddrs *ifa, *i;
+        int r = -ENODEV;
+
+        if (!if_indextoname((unsigned int)ifindex, ifname))
+                return -errno;
+
+        if (getifaddrs(&ifa) < 0)
+                return -errno;
+
+        for (i = ifa; i; i = i->ifa_next) {
+                struct sockaddr_dl *dl = (struct sockaddr_dl *)i->ifa_addr;
+
+                if (!dl || dl->sdl_family != AF_LINK)
+                        continue;
+                if (dl->sdl_alen != ETHER_ADDR_LEN)
+                        continue;
+                if (strcmp(i->ifa_name, ifname) != 0)
+                        continue;
+
+                memcpy(mac, LLADDR(dl), ETHER_ADDR_LEN);
+                r = 0;
+                break;
+        }
+
+        freeifaddrs(ifa);
+        return r;
+}
+
+/**
+ * packet_sendto_udp() - send a UDP packet on a BPF device
+ *
+ * See the Linux file for what this is for.  The difference is that the
+ * Ethernet header is built here rather than by the kernel, so @dest_haddr is
+ * read for the destination address and the interface index, and the source
+ * address is looked up.
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+int packet_sendto_udp(int sockfd,
+                      const void *buf,
+                      size_t n_buf,
+                      size_t *n_transmittedp,
+                      const struct sockaddr_in *src_paddr,
+                      const struct packet_sockaddr_ll *dest_haddr,
+                      const struct sockaddr_in *dest_paddr,
+                      uint8_t dscp) {
+        uint8_t ether_hdr[PACKET_ETHER_HDR_LEN];
+        struct ip ip_hdr = {};
+        struct udphdr udp_hdr = {};
+        struct iovec iov[4];
+        uint16_t sum;
+        ssize_t pktlen;
+        int r;
+
+        if (dest_haddr->sll_halen != ETHER_ADDR_LEN)
+                return -EINVAL;
+
+        memcpy(ether_hdr, dest_haddr->sll_addr, ETHER_ADDR_LEN);
+        r = packet_bsd_hwaddr(dest_haddr->sll_ifindex, ether_hdr + ETHER_ADDR_LEN);
+        if (r)
+                return r;
+        {
+                uint16_t type = htons(ETHERTYPE_IP);
+
+                memcpy(ether_hdr + 2 * ETHER_ADDR_LEN, &type, sizeof(type));
+        }
+
+        /*
+         * The header is written field by field rather than with a designated
+         * initialiser, because ip_v and ip_hl are bitfields and the order the
+         * compiler lays them out is not something to rely on in a struct that
+         * goes on the wire.  Assigning them by name is defined; assuming their
+         * position is not.
+         */
+        ip_hdr.ip_v = IPVERSION;
+        ip_hdr.ip_hl = PACKET_IP_HDR_LEN / 4;
+        ip_hdr.ip_tos = dscp << 2;
+        ip_hdr.ip_len = htons(PACKET_IP_HDR_LEN + PACKET_UDP_HDR_LEN + n_buf);
+        ip_hdr.ip_off = htons(IP_DF);
+        ip_hdr.ip_ttl = IPDEFTTL;
+        ip_hdr.ip_p = IPPROTO_UDP;
+        ip_hdr.ip_src = src_paddr->sin_addr;
+        ip_hdr.ip_dst = dest_paddr->sin_addr;
+        ip_hdr.ip_sum = packet_internet_checksum((void *)&ip_hdr, sizeof(ip_hdr));
+
+        udp_hdr.uh_sport = src_paddr->sin_port;
+        udp_hdr.uh_dport = dest_paddr->sin_port;
+        udp_hdr.uh_ulen = htons(PACKET_UDP_HDR_LEN + n_buf);
+
+        sum = packet_internet_checksum_udp(&src_paddr->sin_addr,
+                                           &dest_paddr->sin_addr,
+                                           ntohs(src_paddr->sin_port),
+                                           ntohs(dest_paddr->sin_port),
+                                           buf,
+                                           n_buf,
+                                           0);
+
+        /*
+         * 0x0000 and 0xffff are equivalent for computing the UDP checksum, but
+         * 0x0000 is reserved in UDP headers, to mean that the checksum is not
+         * set and should be ignored by the receiver.  Hence, flip it to 0xffff
+         * in that case.
+         */
+        udp_hdr.uh_sum = sum ?: 0xffff;
+
+        iov[0].iov_base = ether_hdr;
+        iov[0].iov_len = sizeof(ether_hdr);
+        iov[1].iov_base = &ip_hdr;
+        iov[1].iov_len = PACKET_IP_HDR_LEN;
+        iov[2].iov_base = &udp_hdr;
+        iov[2].iov_len = PACKET_UDP_HDR_LEN;
+        iov[3].iov_base = (void *)buf;
+        iov[3].iov_len = n_buf;
+
+        pktlen = writev(sockfd, iov, 4);
+        if (pktlen < 0)
+                return -errno;
+
+        /*
+         * Unlike the Linux kernel, which may prepend VNET headers and report a
+         * larger length, a BPF write puts exactly the bytes given on the wire
+         * or fails.  A short write means the frame did not go out whole, which
+         * is not something the caller can retry meaningfully.
+         */
+        if ((size_t)pktlen != sizeof(ether_hdr) + PACKET_IP_HDR_LEN +
+                              PACKET_UDP_HDR_LEN + n_buf)
+                return -EIO;
+
+        *n_transmittedp = n_buf;
+        return 0;
+}
+
+/**
+ * packet_recvfrom_udp() - receive a UDP packet from a BPF device
+ *
+ * A BPF read returns as many frames as were waiting, each behind a
+ * struct bpf_hdr, into a buffer that must be exactly the size the kernel
+ * asked for (BIOCGBLEN).  Only the first packet that survives the checks is
+ * returned; the rest of the buffer is dropped, which matches what the caller
+ * expects from the Linux side - one call, one packet - and DHCP never has a
+ * backlog worth keeping.
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+/**
+ * packet_bsd_parse() - pull the first usable UDP payload out of a BPF buffer
+ * @rbuf:               what one read() returned
+ * @len:                how many bytes it returned
+ *
+ * This is separate from the read so that it can be measured.  The framing is
+ * the part most likely to be wrong - a frame misplaced by the fourteen bytes
+ * of the Ethernet header still looks like "one packet was received" - and a
+ * test cannot get a BPF device without root, nor fake one with a pipe, because
+ * the read size has to come from BIOCGBLEN.  Given a buffer, this function is
+ * pure.
+ *
+ * Return: 0 on success or when nothing usable was found; @n_transmittedp says
+ *         which.
+ */
+static int packet_bsd_parse(const uint8_t *rbuf,
+                            size_t len,
+                            void *buf,
+                            size_t n_buf,
+                            size_t *n_transmittedp,
+                            struct sockaddr_in *src) {
+        size_t off;
+
+        *n_transmittedp = 0;
+
+        for (off = 0; off + sizeof(struct bpf_hdr) <= len; ) {
+                const struct bpf_hdr *bh = (const struct bpf_hdr *)(rbuf + off);
+                const struct ip *ip_hdr;
+                struct udphdr udp_hdr;
+                size_t frame, hdrlen, iplen, udplen;
+                const uint8_t *p;
+
+                if (bh->bh_hdrlen < sizeof(*bh) ||
+                    off + bh->bh_hdrlen + bh->bh_caplen > len)
+                        break;
+
+                frame = bh->bh_caplen;
+                p = rbuf + off + bh->bh_hdrlen;
+                off += BPF_WORDALIGN(bh->bh_hdrlen + bh->bh_caplen);
+
+                /* A truncated capture cannot be told apart from a short packet. */
+                if (bh->bh_caplen != bh->bh_datalen)
+                        continue;
+                if (frame < PACKET_ETHER_HDR_LEN + PACKET_IP_HDR_LEN + PACKET_UDP_HDR_LEN)
+                        continue;
+
+                p += PACKET_ETHER_HDR_LEN;
+                frame -= PACKET_ETHER_HDR_LEN;
+
+                ip_hdr = (const struct ip *)p;
+                if (ip_hdr->ip_v != IPVERSION)
+                        continue;
+
+                hdrlen = (size_t)ip_hdr->ip_hl * 4;
+                if (hdrlen < PACKET_IP_HDR_LEN || hdrlen > frame)
+                        continue;
+
+                if (ip_hdr->ip_p != IPPROTO_UDP)
+                        continue;
+
+                iplen = ntohs(ip_hdr->ip_len);
+                if (iplen > frame || iplen < hdrlen + PACKET_UDP_HDR_LEN)
+                        continue;
+
+                /*
+                 * The IP header checksum is verified here because nothing else
+                 * will: the packet never went through the IP stack.  On Linux
+                 * the kernel had already done it before AF_PACKET saw it.
+                 */
+                if (packet_internet_checksum(p, hdrlen))
+                        continue;
+
+                memcpy(&udp_hdr, p + hdrlen, PACKET_UDP_HDR_LEN);
+                udplen = ntohs(udp_hdr.uh_ulen);
+                if (udplen < PACKET_UDP_HDR_LEN || hdrlen + udplen > iplen)
+                        continue;
+
+                udplen -= PACKET_UDP_HDR_LEN;
+
+                if (udp_hdr.uh_sum &&
+                    packet_internet_checksum_udp(&(struct in_addr){ ip_hdr->ip_src.s_addr },
+                                                 &(struct in_addr){ ip_hdr->ip_dst.s_addr },
+                                                 ntohs(udp_hdr.uh_sport),
+                                                 ntohs(udp_hdr.uh_dport),
+                                                 p + hdrlen + PACKET_UDP_HDR_LEN,
+                                                 udplen,
+                                                 udp_hdr.uh_sum))
+                        continue;
+
+                if (udplen > n_buf)
+                        udplen = n_buf;
+
+                memcpy(buf, p + hdrlen + PACKET_UDP_HDR_LEN, udplen);
+
+                if (src) {
+                        *src = (struct sockaddr_in){
+                                .sin_family = AF_INET,
+                                .sin_addr = ip_hdr->ip_src,
+                                .sin_port = udp_hdr.uh_sport,
+                        };
+                }
+
+                *n_transmittedp = udplen;
+                break;
+        }
+
+        return 0;
+}
+
+/**
+ * packet_recvfrom_udp() - receive a UDP packet from a BPF device
+ *
+ * A BPF read returns as many frames as were waiting, each behind a
+ * struct bpf_hdr, into a buffer that must be exactly the size the kernel asked
+ * for (BIOCGBLEN).  Only the first packet that survives the checks is
+ * returned; the rest of the buffer is dropped, which matches what the caller
+ * expects from the Linux side - one call, one packet - and DHCP never has a
+ * backlog worth keeping.
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+int packet_recvfrom_udp(int sockfd,
+                        void *buf,
+                        size_t n_buf,
+                        size_t *n_transmittedp,
+                        struct sockaddr_in *src) {
+        u_int blen = 0;
+        uint8_t *rbuf;
+        ssize_t len;
+        int r;
+
+        *n_transmittedp = 0;
+
+        if (ioctl(sockfd, BIOCGBLEN, &blen) < 0)
+                return -errno;
+        if (!blen)
+                return -EIO;
+
+        /*
+         * The read buffer has to be blen and cannot be a fixed size, so it is
+         * allocated per call.  DHCP is a handful of packets per lease, not a
+         * packet loop, so the allocation is not on any hot path.
+         */
+        rbuf = malloc(blen);
+        if (!rbuf)
+                return -ENOMEM;
+
+        len = read(sockfd, rbuf, blen);
+        if (len < 0) {
+                /*
+                 * A wakeup that turns out to carry nothing is normal: the
+                 * filter may have dropped everything that arrived.
+                 */
+                r = (errno == EAGAIN || errno == EINTR) ? 0 : -errno;
+        } else {
+                r = packet_bsd_parse(rbuf, (size_t)len, buf, n_buf, n_transmittedp, src);
+        }
+
+        free(rbuf);
+        return r;
+}
+
+/**
+ * packet_shutdown() - stop a BPF device from delivering anything
+ *
+ * The Linux file attaches a filter that returns zero for every packet.  The
+ * same program, in the same instruction set, goes on with BIOCSETF - classic
+ * BPF is what both sides speak, and BPF_STMT spells the same thing in
+ * <net/bpf.h> as it does in <linux/filter.h>.
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+int packet_shutdown(int sockfd) {
+        struct bpf_insn insns[] = {
+                BPF_STMT(BPF_RET + BPF_K, 0), /* discard all packets */
+        };
+        struct bpf_program prog = {
+                .bf_len = sizeof(insns) / sizeof(insns[0]),
+                .bf_insns = insns,
+        };
+
+        if (ioctl(sockfd, BIOCSETF, &prog) < 0)
+                return -errno;
+
+        return 0;
+}
