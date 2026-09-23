$NetBSD$

Keep what is portable here and move the rest out.

Sending is the same everywhere: a datagram goes out with send(), a broadcast
with sendto(), and a packet that has to reach a host with no address yet is
built by util/packet.c.  Opening the sockets is not - the filter, the interface
binding and the way the kernel reports which address a packet was addressed to
all differ - so the four constructors and the one receive that reads ancillary
data go to n-dhcp4-socket-linux.c and n-dhcp4-socket-bsd.c.

The link address this file fills in now carries only what the caller knows: the
interface index, the hardware address and its length.  sll_family and
sll_protocol are whatever the system that consumes it wants them to be, so
packet_sendto_udp() sets them.

--- src/n-dhcp4/src/n-dhcp4-socket.c.orig
+++ src/n-dhcp4/src/n-dhcp4-socket.c
@@ -1,342 +1,33 @@
 /*
- * DHCP specific low-level socket helpers
+ * DHCP specific low-level socket helpers - the portable half
+ *
+ * Sending is the same everywhere: a datagram goes out with send(), a broadcast
+ * with sendto(), and a packet that has to reach a host with no address yet is
+ * built by util/packet.c.  Opening the sockets is not - the filter, the
+ * interface binding and the way the kernel reports which address a packet was
+ * addressed to all differ - so the four constructors and the one receive that
+ * reads ancillary data live in n-dhcp4-socket-linux.c and
+ * n-dhcp4-socket-bsd.c.
  */
 
 #include <c-stdaux.h>
 #include <errno.h>
-#include <linux/filter.h>
-#include <sys/socket.h> /* needed by linux/if.h */
-#include <linux/if.h>
-#include <linux/if_packet.h>
-#include <linux/netdevice.h>
-#include <linux/udp.h>
+#include <netinet/in.h>
 #include <netinet/ip.h>
 #include <stddef.h>
 #include <stdlib.h>
 #include <stdint.h>
 #include <string.h>
+#include <sys/socket.h>
 #include <sys/types.h>
 #include "n-dhcp4-private.h"
 #include "util/packet.h"
 #include "util/socket.h"
 
-/**
- * n_dhcp4_c_socket_packet_new() - create a new DHCP4 client packet socket
- * @sockfdp:            return argument for the new socket
- * @ifindex:            interface index to bind to
- *
- * Create a new AF_PACKET/SOCK_DGRAM socket usable to listen to and send DHCP client
- * packets before an IP address has been configured.
- *
- * Only unfragmented DHCP packets from a server to a client destined for the given
- * ifindex is returned.
- *
- * Return: 0 on success, or a negative error code on failure.
- */
-int n_dhcp4_c_socket_packet_new(int *sockfdp, int ifindex) {
-        _c_cleanup_(c_closep) int sockfd = -1;
-        struct sock_filter filter[] = {
-                /*
-                 * IP
-                 *
-                 * Check
-                 *  - UDP
-                 *  - Unfragmented
-                 *  - Large enough to fit the DHCP header
-                 *
-                 *  Leave X the size of the IP header, for future indirect reads.
-                 */
-                BPF_STMT(BPF_LD + BPF_B + BPF_ABS, offsetof(struct iphdr, protocol)),                           /* A <- IP protocol */
-                BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, IPPROTO_UDP, 1, 0),                                         /* IP protocol == UDP ? */
-                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
 
-                BPF_STMT(BPF_LD + BPF_H + BPF_ABS, offsetof(struct iphdr, frag_off)),                           /* A <- Flags + Fragment offset */
-                BPF_STMT(BPF_ALU + BPF_AND + BPF_K, IP_MF | IP_OFFMASK),                                        /* A <- A & (IP_MF | IP_OFFMASK) */
-                BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, 0, 1, 0),                                                   /* fragmented packet ? */
-                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
 
-                BPF_STMT(BPF_LDX + BPF_B + BPF_MSH, 0),                                                         /* X <- IP header length */
-                BPF_STMT(BPF_LD + BPF_W + BPF_LEN, 0),                                                          /* A <- packet length */
-                BPF_STMT(BPF_ALU + BPF_SUB + BPF_X, 0),                                                         /* A -= X */
-                BPF_JUMP(BPF_JMP + BPF_JGE + BPF_K, sizeof(struct udphdr) + sizeof(NDhcp4Message), 1, 0),       /* packet >= DHCPPacket ? */
-                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
 
-                /*
-                 * UDP
-                 *
-                 * Check
-                 *  - DHCP client port
-                 *
-                 * Leave X the size of IP and UDP headers, for future indirect reads.
-                 */
-                BPF_STMT(BPF_LD + BPF_H + BPF_IND, offsetof(struct udphdr, dest)),                              /* A <- UDP destination port */
-                BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, N_DHCP4_NETWORK_CLIENT_PORT, 1, 0),                         /* UDP destination port == DHCP client port ? */
-                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
 
-                BPF_STMT(BPF_LD + BPF_W + BPF_K, sizeof(struct udphdr)),                                        /* A <- size of UDP header */
-                BPF_STMT(BPF_ALU + BPF_ADD + BPF_X, 0),                                                         /* A += X */
-                BPF_STMT(BPF_MISC + BPF_TAX, 0),                                                                /* X <- A */
-
-                /*
-                 * DHCP
-                 *
-                 * Check
-                 *  - BOOTREPLY (from server to client)
-                 *  - DHCP magic cookie
-                 */
-                BPF_STMT(BPF_LD + BPF_B + BPF_IND, offsetof(NDhcp4Header, op)),                                 /* A <- DHCP op */
-                BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, N_DHCP4_OP_BOOTREPLY, 1, 0),                                /* op == BOOTREPLY ? */
-                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
-
-                BPF_STMT(BPF_LD + BPF_W + BPF_IND, offsetof(NDhcp4Message, magic)),                             /* A <- DHCP magic cookie */
-                BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, N_DHCP4_MESSAGE_MAGIC, 1, 0),                               /* cookie == DHCP magic cookie ? */
-                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
-
-                BPF_STMT(BPF_RET + BPF_K, 65535),                                                               /* return all */
-        };
-        struct sock_fprog fprog = {
-                .filter = filter,
-                .len = sizeof(filter) / sizeof(filter[0]),
-        };
-        struct sockaddr_ll addr = {
-                .sll_family = AF_PACKET,
-                .sll_protocol = htons(ETH_P_IP),
-                .sll_ifindex = ifindex,
-        };
-        int r, on = 1;
-
-        sockfd = socket(AF_PACKET, SOCK_DGRAM | SOCK_CLOEXEC | SOCK_NONBLOCK, 0);
-        if (sockfd < 0)
-                return -errno;
-
-        r = setsockopt(sockfd, SOL_SOCKET, SO_ATTACH_FILTER, &fprog, sizeof(fprog));
-        if (r < 0)
-                return -errno;
-
-        /* We need the flag that tells us if the checksum is correct. */
-        r = setsockopt(sockfd, SOL_PACKET, PACKET_AUXDATA, &on, sizeof(on));
-        if (r < 0)
-                return -errno;
-
-        r = bind(sockfd, (struct sockaddr*)&addr, sizeof(addr));
-        if (r < 0)
-                return -errno;
-
-        *sockfdp = sockfd;
-        sockfd = -1;
-        return 0;
-}
-
-/**
- * n_dhcp4_c_socket_udp_new() - create a new DHCP4 client UDP socket
- * @sockfdp:            return argument for the new socket
- * @ifindex:            interface index to bind to
- * @client_addr:        client address to bind to
- * @server_addr:        server address to connect to
- * @dscp:               the DSCP value
- *
- * Create a new AF_INET/SOCK_DGRAM socket usable to listen to and send DHCP client
- * packets.
- *
- * The client address given in @addr must be configured on the interface @ifindex
- * before the socket is created.
- *
- * Return: 0 on success, or a negative error code on failure.
- */
-int n_dhcp4_c_socket_udp_new(int *sockfdp,
-                             int ifindex,
-                             const struct in_addr *client_addr,
-                             const struct in_addr *server_addr,
-                             uint8_t dscp) {
-        _c_cleanup_(c_closep) int sockfd = -1;
-        struct sock_filter filter[] = {
-                /*
-                 * IP/UDP
-                 *
-                 * Set X to the size of IP and UDP headers, for future indirect reads.
-                 */
-                BPF_STMT(BPF_LDX + BPF_B + BPF_MSH, 0),                                                         /* X <- IP header length */
-                BPF_STMT(BPF_LD + BPF_W + BPF_K, sizeof(struct udphdr)),                                        /* A <- size of UDP header */
-                BPF_STMT(BPF_ALU + BPF_ADD + BPF_X, 0),                                                         /* A += X */
-                BPF_STMT(BPF_MISC + BPF_TAX, 0),                                                                /* X <- A */
-
-                /*
-                 * DHCP
-                 *
-                 * Check
-                 *  - BOOTREPLY (from server to client)
-                 *  - DHCP magic cookie
-                 */
-                BPF_STMT(BPF_LD + BPF_B + BPF_IND, offsetof(NDhcp4Header, op)),                                 /* A <- DHCP op */
-                BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, N_DHCP4_OP_BOOTREPLY, 1, 0),                                /* op == BOOTREPLY ? */
-                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
-
-                BPF_STMT(BPF_LD + BPF_W + BPF_IND, offsetof(NDhcp4Message, magic)),                             /* A <- DHCP magic cookie */
-                BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, N_DHCP4_MESSAGE_MAGIC, 1, 0),                               /* cookie == DHCP magic cookie ? */
-                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
-
-                BPF_STMT(BPF_RET + BPF_K, 65535),                                                               /* return all */
-        };
-        struct sock_fprog fprog = {
-                .filter = filter,
-                .len = sizeof(filter) / sizeof(filter[0]),
-        };
-        struct sockaddr_in saddr = {
-                .sin_family = AF_INET,
-                .sin_addr = *client_addr,
-                .sin_port = htons(N_DHCP4_NETWORK_CLIENT_PORT),
-        };
-        struct sockaddr_in daddr = {
-                .sin_family = AF_INET,
-                .sin_addr = *server_addr,
-                .sin_port = htons(N_DHCP4_NETWORK_SERVER_PORT),
-        };
-        int r, on = 1;
-        int tos = dscp << 2;
-
-        sockfd = socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC | SOCK_NONBLOCK, 0);
-        if (sockfd < 0)
-                return -errno;
-
-        r = setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on));
-        if (r < 0)
-                return -errno;
-
-        r = setsockopt(sockfd, SOL_SOCKET, SO_ATTACH_FILTER, &fprog, sizeof(fprog));
-        if (r < 0)
-                return -errno;
-
-        r = socket_bind_if(sockfd, ifindex);
-        if (r)
-                return r;
-
-        r = setsockopt(sockfd, SOL_SOCKET, SO_BROADCAST, &on, sizeof(on));
-        if (r < 0)
-                return -errno;
-
-        r = setsockopt(sockfd, IPPROTO_IP, IP_TOS, &tos, sizeof(tos));
-        if (r < 0)
-                return -errno;
-
-        r = bind(sockfd, (struct sockaddr*)&saddr, sizeof(saddr));
-        if (r < 0)
-                return -errno;
-
-        r = connect(sockfd, (struct sockaddr*)&daddr, sizeof(daddr));
-        if (r < 0)
-                return -errno;
-
-        *sockfdp = sockfd;
-        sockfd = -1;
-        return 0;
-}
-
-/**
- * n_dhcp4_s_socket_packet_new() - create a new DHCP4 server packet socket
- * @sockfdp:            return argument for the new socket
- *
- * Create a new AF_PACKET/SOCK_DGRAM socket usable to send DHCP packets to clients
- * before they have an IP address configured, on the given interface.
- *
- * Return: 0 on success, or a negative error code on failure.
- */
-int n_dhcp4_s_socket_packet_new(int *sockfdp) {
-        _c_cleanup_(c_closep) int sockfd = -1;
-
-        sockfd = socket(AF_PACKET, SOCK_DGRAM | SOCK_CLOEXEC | SOCK_NONBLOCK, 0);
-        if (sockfd < 0)
-                return -errno;
-
-        *sockfdp = sockfd;
-        sockfd = -1;
-        return 0;
-}
-
-/**
- * n_dhcp4_s_socket_udp_new() - create a new DHCP4 server UDP socket
- * @sockfdp:            return argument for the new socket
- * @ifindex:            intercafe index to bind to
- *
- * Create a new AF_INET/SOCK_DGRAM socket usable to listen to DHCP server packets,
- * on the given interface.
- *
- * Return: 0 on success, or a negative error code on failure.
- */
-int n_dhcp4_s_socket_udp_new(int *sockfdp, int ifindex) {
-        _c_cleanup_(c_closep) int sockfd = -1;
-        struct sock_filter filter[] = {
-                /*
-                 * IP/UDP
-                 *
-                 * Set X to the size of IP and UDP headers, for future indirect reads.
-                 */
-                BPF_STMT(BPF_LDX + BPF_B + BPF_MSH, 0),                                                         /* X <- IP header length */
-                BPF_STMT(BPF_LD + BPF_W + BPF_K, sizeof(struct udphdr)),                                        /* A <- size of UDP header */
-                BPF_STMT(BPF_ALU + BPF_ADD + BPF_X, 0),                                                         /* A += X */
-                BPF_STMT(BPF_MISC + BPF_TAX, 0),                                                                /* X <- A */
-
-                /*
-                 * DHCP
-                 *
-                 * Check
-                 *  - BOOTREQUEST (from client to server)
-                 *  - DHCP magic cookie
-                 */
-
-                BPF_STMT(BPF_LD + BPF_B + BPF_IND, offsetof(NDhcp4Header, op)),                                 /* A <- DHCP op */
-                BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, N_DHCP4_OP_BOOTREQUEST, 1, 0),                              /* op == BOOTREQUEST ? */
-                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
-
-                BPF_STMT(BPF_LD + BPF_W + BPF_IND, offsetof(NDhcp4Message, magic)),                             /* A <- DHCP magic cookie */
-                BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, N_DHCP4_MESSAGE_MAGIC, 1, 0),                               /* cookie == DHCP magic cookie ? */
-                BPF_STMT(BPF_RET + BPF_K, 0),                                                                   /* ignore */
-
-                BPF_STMT(BPF_RET + BPF_K, 65535),                                                               /* return all */
-        };
-        struct sock_fprog fprog = {
-                .filter = filter,
-                .len = sizeof(filter) / sizeof(filter[0]),
-        };
-        struct sockaddr_in addr = {
-                .sin_family = AF_INET,
-                .sin_addr = { INADDR_ANY },
-                .sin_port = htons(N_DHCP4_NETWORK_SERVER_PORT),
-        };
-        int r, tos = IPTOS_CLASS_CS6, on = 1;
-
-        sockfd = socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC | SOCK_NONBLOCK, 0);
-        if (sockfd < 0)
-                return -errno;
-
-        r = setsockopt(sockfd, SOL_SOCKET, SO_ATTACH_FILTER, &fprog, sizeof(fprog));
-        if (r < 0)
-                return -errno;
-
-        r = socket_bind_if(sockfd, ifindex);
-        if (r)
-                return r;
-
-        r = setsockopt(sockfd, SOL_SOCKET, SO_BROADCAST, &on, sizeof(on));
-        if (r < 0)
-                return -errno;
-
-        r = setsockopt(sockfd, IPPROTO_IP, IP_TOS, &tos, sizeof(tos));
-        if (r < 0)
-                return -errno;
-
-        r = setsockopt(sockfd, IPPROTO_IP, IP_PKTINFO, &on, sizeof(on));
-        if (r < 0)
-                return -errno;
-
-        r = bind(sockfd, (struct sockaddr*)&addr, sizeof(addr));
-        if (r < 0)
-                return -errno;
-
-        *sockfdp = sockfd;
-        sockfd = -1;
-        return 0;
-}
-
 static int n_dhcp4_socket_packet_send(int sockfd,
                                       int ifindex,
                                       const struct sockaddr_in *src_paddr,
@@ -345,9 +36,15 @@
                                       const struct sockaddr_in *dest_paddr,
                                       uint8_t dscp,
                                       NDhcp4Outgoing *message) {
+        /*
+         * Only what the caller knows is filled in here.  sll_family and
+         * sll_protocol are whatever the system that consumes this address
+         * wants them to be - Linux hands the whole thing to sendmsg() and
+         * needs AF_PACKET, the BSDs build the Ethernet header themselves and
+         * read nothing but the index and the address - so they are set by
+         * packet_sendto_udp() rather than by every caller of it.
+         */
         struct packet_sockaddr_ll haddr = {
-                .sll_family = AF_PACKET,
-                .sll_protocol = htons(ETH_P_IP),
                 .sll_ifindex = ifindex,
                 .sll_halen = halen,
         };
@@ -586,60 +283,8 @@
         message = NULL;
         return 0;
 }
-
-static int n_dhcp4_socket_udp_recv(int sockfd,
-                                   uint8_t *buf,
-                                   size_t n_buf,
-                                   NDhcp4Incoming **messagep,
-                                   struct in_pktinfo *pktinfo) {
-        _c_cleanup_(n_dhcp4_incoming_freep) NDhcp4Incoming *message = NULL;
-        struct iovec iov = {
-                .iov_base = buf,
-                .iov_len = n_buf,
-        };
-        uint8_t cmsgbuf[CMSG_LEN(sizeof(struct in_pktinfo))];
-        struct msghdr msg = {
-                .msg_iov = &iov,
-                .msg_iovlen = 1,
-                .msg_control = cmsgbuf,
-                .msg_controllen = sizeof(cmsgbuf),
-        };
-        ssize_t len;
-        int r;
 
-        len = recvmsg(sockfd, &msg, MSG_TRUNC);
-        if (len < 0) {
-                if (errno == ENETDOWN)
-                        return N_DHCP4_E_DOWN;
-                else if (errno == EAGAIN)
-                        return N_DHCP4_E_AGAIN;
-                else
-                        return -errno;
-        } else if (len == 0 || (size_t)len > n_buf) {
-                return N_DHCP4_E_MALFORMED;
-        }
 
-        r = n_dhcp4_incoming_new(&message, buf, len);
-        if (r)
-                return r;
-
-        if (pktinfo) {
-                struct cmsghdr *cmsg;
-
-                cmsg = CMSG_FIRSTHDR(&msg);
-                c_assert(cmsg);
-                c_assert(cmsg->cmsg_level == IPPROTO_IP);
-                c_assert(cmsg->cmsg_type == IP_PKTINFO);
-                c_assert(cmsg->cmsg_len == CMSG_LEN(sizeof(struct in_pktinfo)));
-
-                memcpy(pktinfo, (void*)CMSG_DATA(cmsg), sizeof(struct in_pktinfo));
-        }
-
-        *messagep = message;
-        message = NULL;
-        return 0;
-}
-
 int n_dhcp4_c_socket_udp_recv(int sockfd,
                               uint8_t *buf,
                               size_t n_buf,
@@ -652,17 +297,23 @@
                               size_t n_buf,
                               NDhcp4Incoming **messagep,
                               struct sockaddr_in *dest) {
-        struct in_pktinfo pktinfo = {};
+        struct in_addr dest_addr = {};
         int r;
 
-        r = n_dhcp4_socket_udp_recv(sockfd, buf, n_buf, messagep, &pktinfo);
+        /*
+         * Only the address the packet was addressed to is wanted, which is
+         * what every system can report - Linux through IP_PKTINFO, the BSDs
+         * through IP_RECVDSTADDR.  Passing the whole struct in_pktinfo would
+         * have tied this to the one that has it.
+         */
+        r = n_dhcp4_socket_udp_recv(sockfd, buf, n_buf, messagep, &dest_addr);
         if (r)
                 return r;
 
         if (dest) {
                 dest->sin_family = AF_INET;
                 dest->sin_port = htons(N_DHCP4_NETWORK_SERVER_PORT);
-                dest->sin_addr.s_addr = pktinfo.ipi_addr.s_addr;
+                dest->sin_addr = dest_addr;
         }
 
         return 0;
