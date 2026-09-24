/*
 * n-dhcp4 の client が、実際に線へ DHCPDISCOVER を出すかを測る。
 *
 * 建ったことでも繋がったことでもない。BPF を開き、filter を張り、packet を
 * 組み、timer で送信を刻み、という経路が全部繋がっていないと何も出てこない。
 *
 * 借り物の segment へ broadcast を撒きたくないので tap を一本立てて、そこで
 * やる。tap には誰も繋がっていないので、出した frame は外へ出ない。捕まえる
 * のは別に開いた BPF で、こちらも同じ tap を見ている。
 */
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <ifaddrs.h>
/*
 * OpenBSD の <net/bpf.h> は int32_t と u_int32_t を自分で連れてこない。
 *
 *	/usr/include/net/bpf.h:46:9: error: unknown type name 'int32_t'
 */
#include <sys/types.h>
#include <net/bpf.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <time.h>
#include <unistd.h>
#include "n-dhcp4.h"

#ifdef __NetBSD__
#  include <net/if_ether.h>
#else
#  include <net/ethernet.h>
#endif

#define E 14

static int open_capture(const char *ifname, size_t *blenp) {
        struct ifreq ifr = {};
        u_int on = 1, blen = 0;
        int fd;

        fd = open("/dev/bpf", O_RDWR);
        if (fd < 0) { perror("/dev/bpf"); return -1; }
        strncpy(ifr.ifr_name, ifname, sizeof(ifr.ifr_name) - 1);
        if (ioctl(fd, BIOCSETIF, &ifr) < 0) { perror("BIOCSETIF"); close(fd); return -1; }
        if (ioctl(fd, BIOCIMMEDIATE, &on) < 0) { perror("BIOCIMMEDIATE"); close(fd); return -1; }
        if (ioctl(fd, BIOCGBLEN, &blen) < 0) { perror("BIOCGBLEN"); close(fd); return -1; }
        (void)fcntl(fd, F_SETFL, O_NONBLOCK);
        *blenp = blen;
        return fd;
}

int main(int argc, char **argv) {
        const char *ifname = argc > 1 ? argv[1] : "tap0";
        NDhcp4ClientConfig *cfg = NULL;
        NDhcp4ClientProbeConfig *pcfg = NULL;
        NDhcp4Client *client = NULL;
        NDhcp4ClientProbe *probe = NULL;
        struct ifaddrs *ifa, *i;
        uint8_t mac[ETHER_ADDR_LEN], *rbuf;
        unsigned idx = 0;
        size_t blen = 0;
        int cap, r, seen = 0, rounds;

        if (getifaddrs(&ifa)) return 1;
        for (i = ifa; i; i = i->ifa_next) {
                struct sockaddr_dl *dl = (struct sockaddr_dl *)i->ifa_addr;
                if (!dl || dl->sdl_family != AF_LINK) continue;
                if (strcmp(i->ifa_name, ifname)) continue;
                if (dl->sdl_alen != ETHER_ADDR_LEN) continue;
                memcpy(mac, LLADDR(dl), ETHER_ADDR_LEN);
                idx = if_nametoindex(ifname);
                break;
        }
        freeifaddrs(ifa);
        if (!idx) { printf("%s が無いか MAC を持たない\n", ifname); return 77; }
        printf("%s (index %u) %02x:%02x:%02x:%02x:%02x:%02x\n", ifname, idx,
               mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);

        cap = open_capture(ifname, &blen);
        if (cap < 0) return 77;
        rbuf = malloc(blen);
        if (!rbuf) return 1;

        if (n_dhcp4_client_config_new(&cfg)) return 1;
        n_dhcp4_client_config_set_ifindex(cfg, (int)idx);
        n_dhcp4_client_config_set_transport(cfg, N_DHCP4_TRANSPORT_ETHERNET);
        n_dhcp4_client_config_set_mac(cfg, mac, sizeof(mac));
        {
                uint8_t bcast[ETHER_ADDR_LEN];
                memset(bcast, 0xff, sizeof(bcast));
                n_dhcp4_client_config_set_broadcast_mac(cfg, bcast, sizeof(bcast));
        }

        r = n_dhcp4_client_new(&client, cfg);
        printf("n_dhcp4_client_new         -> %d%s\n", r,
               r ? (r < 0 ? strerror(-r) : " (内部符号)") : "");
        if (r) { return r == -EACCES || r == -EPERM ? 77 : 1; }

        if (n_dhcp4_client_probe_config_new(&pcfg)) return 1;
        n_dhcp4_client_probe_config_set_start_delay(pcfg, 1); /* 待たずに出す */

        r = n_dhcp4_client_probe(client, &probe, pcfg);
        printf("n_dhcp4_client_probe       -> %d\n", r);
        if (r) return 1;

        for (rounds = 0; rounds < 120 && !seen; ++rounds) {
                ssize_t len;
                size_t off;
                struct timespec ts = { .tv_nsec = 50000000 };

                do { r = n_dhcp4_client_dispatch(client); } while (r == N_DHCP4_E_PREEMPTED);
                if (r) { printf("dispatch -> %d\n", r); break; }

                len = read(cap, rbuf, blen);
                for (off = 0; len > 0 && off + sizeof(struct bpf_hdr) <= (size_t)len; ) {
                        const struct bpf_hdr *bh = (const struct bpf_hdr *)(rbuf + off);
                        const uint8_t *p = rbuf + off + bh->bh_hdrlen;
                        size_t n = bh->bh_caplen;
                        off += BPF_WORDALIGN(bh->bh_hdrlen + bh->bh_caplen);

                        if (n < E + 20 + 8 + 240) continue;
                        if (ntohs(*(const uint16_t *)(p + 12)) != ETHERTYPE_IP) continue;
                        if (p[E + 9] != IPPROTO_UDP) continue;
                        if (ntohs(*(const uint16_t *)(p + E + 20 + 2)) != 67) continue;

                        printf("\n捕まえた frame %zu byte\n", n);
                        printf("  宛先 MAC   %02x:%02x:%02x:%02x:%02x:%02x %s\n",
                               p[0],p[1],p[2],p[3],p[4],p[5],
                               memcmp(p, "\xff\xff\xff\xff\xff\xff", 6) ? "★broadcast でない" : "(broadcast)");
                        printf("  送り元 MAC %02x:%02x:%02x:%02x:%02x:%02x %s\n",
                               p[6],p[7],p[8],p[9],p[10],p[11],
                               memcmp(p + 6, mac, 6) ? "★interface の物でない" : "(一致)");
                        printf("  UDP        %u -> %u\n",
                               ntohs(*(const uint16_t *)(p + E + 20)),
                               ntohs(*(const uint16_t *)(p + E + 20 + 2)));
                        printf("  DHCP op    %u %s\n", p[E + 28],
                               p[E + 28] == 1 ? "(BOOTREQUEST)" : "★BOOTREQUEST でない");
                        printf("  htype/hlen %u/%u\n", p[E + 29], p[E + 30]);
                        printf("  chaddr     %02x:%02x:%02x:%02x:%02x:%02x %s\n",
                               p[E+28+28],p[E+28+29],p[E+28+30],p[E+28+31],p[E+28+32],p[E+28+33],
                               memcmp(p + E + 28 + 28, mac, 6) ? "★MAC でない" : "(一致)");
                        {
                                uint32_t magic;
                                memcpy(&magic, p + E + 28 + 236, 4);
                                printf("  magic      0x%08x %s\n", ntohl(magic),
                                       ntohl(magic) == 0x63825363 ? "(DHCP)" : "★違う");
                                /* option 53 = message type。1 が DISCOVER */
                                {
                                        const uint8_t *o = p + E + 28 + 240;
                                        const uint8_t *end = p + n;
                                        while (o + 1 < end && *o != 255) {
                                                if (*o == 0) { ++o; continue; }
                                                if (*o == 53 && o + 2 < end)
                                                        printf("  msg type   %u %s\n", o[2],
                                                               o[2] == 1 ? "(DHCPDISCOVER)" : "★DISCOVER でない");
                                                o += 2 + o[1];
                                        }
                                }
                        }
                        seen = 1;
                        break;
                }
                nanosleep(&ts, NULL);
        }

        n_dhcp4_client_probe_free(probe);
        n_dhcp4_client_unref(client);
        n_dhcp4_client_config_free(cfg);
        n_dhcp4_client_probe_config_free(pcfg);
        close(cap);
        free(rbuf);

        printf("\n%s\n", seen ? "=== 線に DHCPDISCOVER が出た ===" : "=== 何も出なかった ===");
        return seen ? 0 : 1;
}
