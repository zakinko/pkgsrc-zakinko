/*
 * n-dhcp4 の client に、実際に lease を取らせる。
 *
 * 送信は t-wire で線の byte まで測った。**受信は測っていない** — BPF から
 * 読み、bpf_hdr を歩き、filter が通した frame を解析し、状態機械が次の段へ
 * 進む、という経路は一度も走っていない。合成 buffer の単体 test は通って
 * いるが、それは kernel が返す形をこちらが正しく想像できていた場合の話で
 * ある。
 *
 * そこで tap の上に最小の DHCP server を置く。同じ tap を見ている BPF から
 * 読んで、DISCOVER には OFFER を、REQUEST には ACK を返す。tap には誰も
 * 繋がっていないので、frame は外へ出ない。
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
#include <netinet/in_systm.h>
#include <netinet/ip.h>
#include <netinet/udp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/uio.h>
#include <time.h>
#include <unistd.h>
#include "n-dhcp4.h"

/* private.h の中の値。test から引くより、RFC2132 の番号をそのまま書く。 */
#define DHCP_DISCOVER 1
#define DHCP_OFFER    2
#define DHCP_REQUEST  3
#define DHCP_DECLINE  4
#define DHCP_ACK      5

/*
 * struct ether_header と ETHERTYPE_IP。<net/ethernet.h> は FreeBSD と
 * DragonFly の綴りで、NetBSD にも OpenBSD にも無い。四つとも持っている
 * <netinet/if_ether.h> に寄せる。あれは sockaddr と in_addr を、OpenBSD では
 * さらに arphdr を必要とするのに自分では連れてこないので、順に読む。
 * package 側の当て物と同じ形にしてある。
 */
#include <sys/types.h>
#include <sys/socket.h>
#include <net/if_arp.h>
#include <netinet/in.h>
#include <netinet/if_ether.h>

#define E 14
#define IPH 20
#define UDPH 8
#define DHCP_FIXED 240          /* header 236 + magic 4 */

uint16_t packet_internet_checksum(const uint8_t *data, size_t len);
uint16_t packet_internet_checksum_udp(const struct in_addr *s, const struct in_addr *d,
                                      uint16_t sp, uint16_t dp,
                                      const uint8_t *data, size_t n, uint16_t sum);

static int open_bpf(const char *ifname, size_t *blenp) {
        struct ifreq ifr = {};
        u_int on = 1, blen = 0;
        int fd = open("/dev/bpf", O_RDWR);
        if (fd < 0) return -1;
        strncpy(ifr.ifr_name, ifname, sizeof(ifr.ifr_name) - 1);
        if (ioctl(fd, BIOCSETIF, &ifr) < 0) { close(fd); return -1; }
        if (ioctl(fd, BIOCIMMEDIATE, &on) < 0) { close(fd); return -1; }
        if (ioctl(fd, BIOCSHDRCMPLT, &on) < 0) { close(fd); return -1; }
        if (ioctl(fd, BIOCGBLEN, &blen) < 0) { close(fd); return -1; }
        (void)fcntl(fd, F_SETFL, O_NONBLOCK);
        if (blenp) *blenp = blen;
        return fd;
}

/* client の DHCP message を読み、種類と xid と chaddr を返す */
static int peek_dhcp(const uint8_t *p, size_t n, uint8_t *typep,
                     uint32_t *xidp, uint8_t *chaddr) {
        const uint8_t *o, *end;
        if (n < E + IPH + UDPH + DHCP_FIXED) return -1;
        if (ntohs(*(const uint16_t *)(p + 12)) != ETHERTYPE_IP) return -1;
        if (p[E + 9] != IPPROTO_UDP) return -1;
        if (ntohs(*(const uint16_t *)(p + E + IPH + 2)) != 67) return -1;
        if (p[E + IPH + UDPH] != 1) return -1;          /* BOOTREQUEST */
        memcpy(xidp, p + E + IPH + UDPH + 4, 4);
        memcpy(chaddr, p + E + IPH + UDPH + 28, 6);
        *typep = 0;
        o = p + E + IPH + UDPH + DHCP_FIXED;
        end = p + n;
        while (o + 1 < end && *o != 255) {
                if (*o == 0) { ++o; continue; }
                if (*o == 53 && o + 2 < end) *typep = o[2];
                o += 2 + o[1];
        }
        return *typep ? 0 : -1;
}

/* OFFER / ACK を一本組んで tap へ出す */
static int reply(int fd, const uint8_t *smac, const uint8_t *cmac,
                 uint32_t xid, uint8_t type,
                 struct in_addr sip, struct in_addr yip, struct in_addr mask) {
        uint8_t frame[E + IPH + UDPH + 512] = {};
        uint8_t *dhcp = frame + E + IPH + UDPH;
        struct ip ip = {};
        struct udphdr uh = {};
        size_t dlen, n;
        uint16_t t, sum;
        uint32_t magic = htonl(0x63825363), lease = htonl(20);

        memcpy(frame, cmac, 6);
        memcpy(frame + 6, smac, 6);
        t = htons(ETHERTYPE_IP); memcpy(frame + 12, &t, 2);

        dhcp[0] = 2;                    /* BOOTREPLY */
        dhcp[1] = 1;                    /* htype ethernet */
        dhcp[2] = 6;                    /* hlen */
        memcpy(dhcp + 4, &xid, 4);
        memcpy(dhcp + 16, &yip.s_addr, 4);      /* yiaddr */
        memcpy(dhcp + 20, &sip.s_addr, 4);      /* siaddr */
        memcpy(dhcp + 28, cmac, 6);             /* chaddr */
        memcpy(dhcp + 236, &magic, 4);
        {
                uint8_t *o = dhcp + DHCP_FIXED;
                *o++ = 53; *o++ = 1; *o++ = type;
                *o++ = 54; *o++ = 4; memcpy(o, &sip.s_addr, 4); o += 4;
                *o++ = 51; *o++ = 4; memcpy(o, &lease, 4); o += 4;
                *o++ = 1;  *o++ = 4; memcpy(o, &mask.s_addr, 4); o += 4;
                *o++ = 255;
                dlen = (size_t)(o - dhcp);
                if (dlen < DHCP_FIXED + 60) dlen = DHCP_FIXED + 60; /* 詰める */
        }

        ip.ip_v = 4; ip.ip_hl = 5;
        ip.ip_len = htons((uint16_t)(IPH + UDPH + dlen));
        ip.ip_ttl = 64; ip.ip_p = IPPROTO_UDP;
        ip.ip_src = sip;
        ip.ip_dst.s_addr = INADDR_BROADCAST;
        memcpy(frame + E, &ip, IPH);
        {
                uint16_t c = packet_internet_checksum(frame + E, IPH);
                memcpy(frame + E + 10, &c, 2);
        }

        uh.uh_sport = htons(67); uh.uh_dport = htons(68);
        uh.uh_ulen = htons((uint16_t)(UDPH + dlen));
        sum = packet_internet_checksum_udp(&sip, &ip.ip_dst, 67, 68, dhcp, dlen, 0);
        uh.uh_sum = sum ?: 0xffff;
        memcpy(frame + E + IPH, &uh, UDPH);

        n = E + IPH + UDPH + dlen;
        return write(fd, frame, n) == (ssize_t)n ? 0 : -1;
}

static const char *evname(unsigned e) {
        switch (e) {
        case N_DHCP4_CLIENT_EVENT_OFFER:   return "OFFER";
        case N_DHCP4_CLIENT_EVENT_GRANTED: return "GRANTED";
        case N_DHCP4_CLIENT_EVENT_EXTENDED: return "EXTENDED";
        case N_DHCP4_CLIENT_EVENT_DOWN:    return "DOWN";
        case N_DHCP4_CLIENT_EVENT_LOG:     return "LOG";
        case N_DHCP4_CLIENT_EVENT_RETRACTED: return "RETRACTED";
        case N_DHCP4_CLIENT_EVENT_EXPIRED:   return "EXPIRED";
        case N_DHCP4_CLIENT_EVENT_CANCELLED: return "CANCELLED";
        default: return "?";
        }
}

int main(int argc, char **argv) {
        setvbuf(stdout, NULL, _IONBF, 0);
        const char *ifname = argc > 1 ? argv[1] : "tap0";
        int want_decline = (argc > 2 && !strcmp(argv[2], "decline"));
        NDhcp4ClientConfig *cfg = NULL;
        NDhcp4ClientProbeConfig *pcfg = NULL;
        NDhcp4Client *client = NULL;
        NDhcp4ClientProbe *probe = NULL;
        struct ifaddrs *ifa, *i;
        uint8_t mac[6], smac[6] = { 0x02, 0, 0, 0, 0, 1 }, *rbuf;
        struct in_addr sip, yip, mask;
        unsigned idx = 0;
        size_t blen = 0;
        int srv, usrv = -1, r, rounds, offered = 0, granted = 0, sent_offer = 0, sent_ack = 0;
        int accepted = 0, extended = 0, renew_seen = 0, declined = 0, decline_seen = 0;

        if (getifaddrs(&ifa)) return 1;
        for (i = ifa; i; i = i->ifa_next) {
                struct sockaddr_dl *dl = (struct sockaddr_dl *)i->ifa_addr;
                if (!dl || dl->sdl_family != AF_LINK || dl->sdl_alen != 6) continue;
                if (strcmp(i->ifa_name, ifname)) continue;
                memcpy(mac, LLADDR(dl), 6);
                idx = if_nametoindex(ifname);
                break;
        }
        freeifaddrs(ifa);
        if (!idx) { printf("%s が無い\n", ifname); return 77; }

        inet_aton("10.99.0.1", &sip);
        inet_aton("10.99.0.50", &yip);
        inet_aton("255.255.255.0", &mask);
        printf("%s (index %u), 偽 server %s -> %s を渡す\n",
               ifname, idx, inet_ntoa(sip), "10.99.0.50");

        srv = open_bpf(ifname, &blen);
        if (srv < 0) { perror("bpf"); return 77; }
        rbuf = malloc(blen);
        if (!rbuf) return 1;

        if (n_dhcp4_client_config_new(&cfg)) return 1;
        n_dhcp4_client_config_set_ifindex(cfg, (int)idx);
        n_dhcp4_client_config_set_transport(cfg, N_DHCP4_TRANSPORT_ETHERNET);
        n_dhcp4_client_config_set_mac(cfg, mac, 6);
        { uint8_t b[6]; memset(b, 0xff, 6); n_dhcp4_client_config_set_broadcast_mac(cfg, b, 6); }

        r = n_dhcp4_client_new(&client, cfg);
        if (r) { printf("client_new -> %d\n", r); return r == -EACCES ? 77 : 1; }

        if (n_dhcp4_client_probe_config_new(&pcfg)) return 1;
        n_dhcp4_client_probe_config_set_start_delay(pcfg, 1);
        r = n_dhcp4_client_probe(client, &probe, pcfg);
        if (r) { printf("probe -> %d\n", r); return 1; }

        /*
         * 更新は UDP で来る。client は 10.99.0.50:68 から 10.99.0.1:67 へ
         * unicast する。両方 tap0 に載せてあるので、外へは出ない。
         */
        usrv = socket(AF_INET, SOCK_DGRAM, 0);
        if (usrv >= 0) {
                struct sockaddr_in a = { .sin_family = AF_INET, .sin_port = htons(67) };
                int on = 1;
                a.sin_addr = sip;
                setsockopt(usrv, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on));
                if (bind(usrv, (struct sockaddr *)&a, sizeof(a)) < 0) {
                        printf("  (server の UDP 67 が bind できない: %s)\n", strerror(errno));
                        close(usrv); usrv = -1;
                } else {
                        (void)fcntl(usrv, F_SETFL, O_NONBLOCK);
                }
        }

        for (rounds = 0; rounds < 900 && !extended && !decline_seen; ++rounds) {
                struct timespec ts = { .tv_nsec = 20000000 };
                NDhcp4ClientEvent *ev;
                ssize_t len;
                size_t off;

                do { r = n_dhcp4_client_dispatch(client); } while (r == N_DHCP4_E_PREEMPTED);
                if (r) { printf("dispatch -> %d\n", r); break; }

                while (!n_dhcp4_client_pop_event(client, &ev) && ev) {
                        if (ev->event == N_DHCP4_CLIENT_EVENT_LOG) {
                                if (ev->log.message)
                                        printf("  log: %s\n", ev->log.message);
                                continue;
                        }
                        printf("  事象: %s (%u)\n", evname(ev->event), ev->event);
                        if (ev->event == N_DHCP4_CLIENT_EVENT_OFFER) {
                                offered = 1;
                                r = n_dhcp4_client_lease_select(ev->offer.lease);
                                printf("  lease_select -> %d\n", r);
                        } else if (ev->event == N_DHCP4_CLIENT_EVENT_GRANTED) {
                                granted = 1;
                                /*
                                 * ここで初めて UDP socket が作られる。
                                 * BSD 側の n_dhcp4_c_socket_udp_new() と
                                 * socket_bind_if() の no-op が走る経路で、
                                 * address が interface に載っていないと
                                 * bind が EADDRNOTAVAIL で落ちる。
                                 */
                                if (want_decline) {
                                        /*
                                         * accept の代わりに decline を呼ぶ。
                                         * address はまだ interface に載って
                                         * いないので、DECLINE は生の frame で
                                         * broadcast される — BPF の送信経路を
                                         * もう一度、別の message 種別で通る。
                                         */
                                        r = n_dhcp4_client_lease_decline(ev->granted.lease,
                                                                         "address already in use");
                                        printf("  lease_decline -> %d\n", r);
                                        declined = 1;
                                        continue;
                                }
                                r = n_dhcp4_client_lease_accept(ev->granted.lease);
                                printf("  lease_accept -> %d%s\n", r,
                                       r ? " ★UDP socket が作れない" : "  (UDP socket が出来た)");
                                if (r) return 1;
                                accepted = 1;
                        } else if (ev->event == N_DHCP4_CLIENT_EVENT_EXTENDED) {
                                extended = 1;
                        }
                }

                len = read(srv, rbuf, blen);
                for (off = 0; len > 0 && off + sizeof(struct bpf_hdr) <= (size_t)len; ) {
                        const struct bpf_hdr *bh = (const struct bpf_hdr *)(rbuf + off);
                        const uint8_t *p = rbuf + off + bh->bh_hdrlen;
                        size_t n = bh->bh_caplen;
                        uint8_t type = 0, cmac[6];
                        uint32_t xid = 0;
                        off += BPF_WORDALIGN(bh->bh_hdrlen + bh->bh_caplen);

                        if (bh->bh_caplen != bh->bh_datalen) continue;
                        if (peek_dhcp(p, n, &type, &xid, cmac)) continue;
                        if (memcmp(cmac, mac, 6)) continue;

                        if (type == DHCP_DECLINE) {
                                printf("  server: 生の frame で DECLINE を受けた\n");
                                decline_seen = 1;
                                continue;
                        }
                        if (type == DHCP_DISCOVER && !sent_offer) {
                                printf("  server: DISCOVER を受けて OFFER を返す\n");
                                if (reply(srv, smac, cmac, xid, DHCP_OFFER, sip, yip, mask))
                                        printf("  ★OFFER を書けない\n");
                                sent_offer = 1;
                        } else if (type == DHCP_REQUEST && !sent_ack) {
                                printf("  server: REQUEST を受けて ACK を返す\n");
                                if (reply(srv, smac, cmac, xid, DHCP_ACK, sip, yip, mask))
                                        printf("  ★ACK を書けない\n");
                                sent_ack = 1;
                        }
                }
                /* 更新の REQUEST は UDP で来る */
                if (usrv >= 0 && accepted && !renew_seen) {
                        uint8_t ub[1500];
                        struct sockaddr_in from = {};
                        socklen_t fl = sizeof(from);
                        ssize_t ul = recvfrom(usrv, ub, sizeof(ub), 0,
                                              (struct sockaddr *)&from, &fl);
                        if (ul >= (ssize_t)DHCP_FIXED && ub[0] == 1) {
                                uint8_t t = 0;
                                const uint8_t *o = ub + DHCP_FIXED, *end = ub + ul;
                                while (o + 1 < end && *o != 255) {
                                        if (*o == 0) { ++o; continue; }
                                        if (*o == 53 && o + 2 < end) t = o[2];
                                        o += 2 + o[1];
                                }
                                printf("  server: UDP で %s を受けた (%s:%u から)\n",
                                       t == DHCP_REQUEST ? "REQUEST" : "何か",
                                       inet_ntoa(from.sin_addr), ntohs(from.sin_port));
                                renew_seen = 1;
                                {
                                        /* ACK を同じ経路で返す */
                                        uint8_t ack[512] = {};
                                        uint32_t magic = htonl(0x63825363), lt = htonl(20);
                                        uint8_t *op;
                                        size_t alen;
                                        ack[0] = 2; ack[1] = 1; ack[2] = 6;
                                        memcpy(ack + 4, ub + 4, 4);
                                        memcpy(ack + 16, &yip.s_addr, 4);
                                        memcpy(ack + 28, mac, 6);
                                        memcpy(ack + 236, &magic, 4);
                                        op = ack + DHCP_FIXED;
                                        *op++ = 53; *op++ = 1; *op++ = DHCP_ACK;
                                        *op++ = 54; *op++ = 4; memcpy(op, &sip.s_addr, 4); op += 4;
                                        *op++ = 51; *op++ = 4; memcpy(op, &lt, 4); op += 4;
                                        *op++ = 1;  *op++ = 4; memcpy(op, &mask.s_addr, 4); op += 4;
                                        *op++ = 255;
                                        alen = (size_t)(op - ack);
                                        {
                                                ssize_t sl = sendto(usrv, ack, alen, 0,
                                                                    (struct sockaddr *)&from, fl);
                                                printf("  server: ACK を UDP で返した -> %zd byte%s\n",
                                                       sl, sl < 0 ? strerror(errno) : "");
                                        }
                                }
                        }
                }

                nanosleep(&ts, NULL);
        }

        printf("\nDISCOVER を受けた: %s / OFFER を client が読んだ: %s\n",
               sent_offer ? "はい" : "いいえ", offered ? "はい" : "いいえ");
        printf("REQUEST を受けた: %s / GRANTED: %s\n",
               sent_ack ? "はい" : "いいえ", granted ? "はい" : "いいえ");
        printf("UDP socket が出来た: %s / 更新の REQUEST が UDP で来た: %s / EXTENDED: %s\n",
               accepted ? "はい" : "いいえ", renew_seen ? "はい" : "いいえ",
               extended ? "はい" : "いいえ");

        /*
         * 最後に RELEASE を出させる。これも UDP 経路で、n-dhcp4 の中では
         * 別の送信の口を通る。出たかどうかは偽 server の UDP socket で見る。
         */
        if (extended && usrv >= 0) {
                int released = 0, k;
                r = n_dhcp4_client_probe_release(probe);
                printf("\n  probe_release -> %d\n", r);
                for (k = 0; k < 50 && !released; ++k) {
                        struct timespec ts2 = { .tv_nsec = 20000000 };
                        uint8_t ub[1500];
                        ssize_t ul;

                        do { r = n_dhcp4_client_dispatch(client); } while (r == N_DHCP4_E_PREEMPTED);
                        ul = recv(usrv, ub, sizeof(ub), 0);
                        if (ul >= (ssize_t)DHCP_FIXED && ub[0] == 1) {
                                const uint8_t *o = ub + DHCP_FIXED, *end = ub + ul;
                                uint8_t t = 0;
                                while (o + 1 < end && *o != 255) {
                                        if (*o == 0) { ++o; continue; }
                                        if (*o == 53 && o + 2 < end) t = o[2];
                                        o += 2 + o[1];
                                }
                                if (t == 7) { printf("  server: UDP で RELEASE を受けた\n"); released = 1; }
                        }
                        nanosleep(&ts2, NULL);
                }
                if (!released)
                        printf("  ★RELEASE が来ない\n");
        }

        if (usrv >= 0) close(usrv);

        n_dhcp4_client_probe_free(probe);
        n_dhcp4_client_unref(client);
        n_dhcp4_client_config_free(cfg);
        n_dhcp4_client_probe_config_free(pcfg);
        close(srv);
        free(rbuf);

        if (want_decline) {
                /*
                 * 後片付けは上で済んでいる。ここでもう一度やっていたので、
                 * rbuf は二度 free され、srv は二度 close され、probe と
                 * client も二重に解放されていた。gcc 12 が
                 *   warning: pointer 'rbuf' may be used after 'free'
                 * で教えてくれた。落ちずに通っていたのは運である。
                 */
                printf("\ndecline を呼んだ: %s / server が DECLINE を受けた: %s\n",
                       declined ? "はい" : "いいえ", decline_seen ? "はい" : "いいえ");
                printf("\n%s\n", decline_seen ? "=== DECLINE が線に出た ===" : "=== 出なかった ===");
                return decline_seen ? 0 : 1;
        }

        printf("\n%s\n", extended ? "=== lease を取り、UDP で更新した ==="
                        : granted ? "=== lease は取ったが更新まで行かなかった ==="
                        : "=== 取れなかった ===");
        return extended ? 0 : 1;
}
