/*
 * packet-bsd.c の送受信を、線に出る byte で測る。
 *
 * 送信は pipe へ書かせて、出てきた frame を自分で分解する。「関数が 0 を
 * 返した」ではなく、Ethernet/IP/UDP の各 field が期待どおりで、checksum が
 * 実際に合っているかを見る。checksum は独立に計算した値と比べないと、同じ
 * 間違いで計算して同じ間違いで検算することになる。
 *
 * 受信は kernel が返すのと同じ形の buffer を組んで pipe から読ませる。
 * 14 byte ずれても「一本取れた」は成立するので、payload を一 byte まで
 * 突き合わせる。
 */
#include <arpa/inet.h>
#include <assert.h>
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
#include <sys/socket.h>
#include <unistd.h>
#include "packet.h"

/*
 * 本物を取り込む。写しを置くと、本物を直した日に緑のまま意味を失う。
 * packet_bsd_parse() は static なので、これでしか呼べない。
 */
#include "packet-bsd.c"

#ifdef __NetBSD__
#  include <net/if_ether.h>
#else
#  include <net/ethernet.h>
#endif

uint16_t packet_internet_checksum(const uint8_t *data, size_t len);

static int find_if(unsigned *idxp, uint8_t *mac, char *name) {
        struct ifaddrs *ifa, *i;
        int found = 0;
        if (getifaddrs(&ifa)) return -1;
        for (i = ifa; i; i = i->ifa_next) {
                struct sockaddr_dl *dl = (struct sockaddr_dl *)i->ifa_addr;
                if (!dl || dl->sdl_family != AF_LINK || dl->sdl_alen != ETHER_ADDR_LEN) continue;
                if (i->ifa_flags & IFF_LOOPBACK) continue;
                memcpy(mac, LLADDR(dl), ETHER_ADDR_LEN);
                *idxp = if_nametoindex(i->ifa_name);
                strcpy(name, i->ifa_name);
                found = 1;
                break;
        }
        freeifaddrs(ifa);
        return found ? 0 : -1;
}

static int test_send(void) {
        uint8_t payload[53], frame[2048], mac[ETHER_ADDR_LEN];
        char ifname[IF_NAMESIZE];
        struct sockaddr_in src = { .sin_family = AF_INET, .sin_port = htons(68) };
        struct sockaddr_in dst = { .sin_family = AF_INET, .sin_port = htons(67) };
        struct packet_sockaddr_ll ha = {};
        unsigned idx;
        size_t n = 0;
        ssize_t got;
        int fds[2], r, fail = 0;
        unsigned i;

        if (find_if(&idx, mac, ifname)) { printf("Ethernet が無い\n"); return 77; }
        printf("使う interface: %s (index %u)\n", ifname, idx);

        for (i = 0; i < sizeof(payload); ++i) payload[i] = (uint8_t)(i * 13 + 5);
        inet_aton("192.168.1.2", &src.sin_addr);
        inet_aton("192.168.1.255", &dst.sin_addr);

        ha.sll_ifindex = (int)idx;
        ha.sll_halen = ETHER_ADDR_LEN;
        memset(ha.sll_addr, 0xff, ETHER_ADDR_LEN);

        assert(pipe(fds) == 0);
        r = packet_sendto_udp(fds[1], payload, sizeof(payload), &n, &src, &ha, &dst, 0);
        close(fds[1]);
        if (r) { printf("  ★sendto -> %d\n", r); return 1; }
        if (n != sizeof(payload)) { printf("  ★送った長さ %zu\n", n); fail = 1; }

        got = read(fds[0], frame, sizeof(frame));
        close(fds[0]);
        printf("線に出た長さ: %zd (期待 %zu)\n", got, 14 + 20 + 8 + sizeof(payload));
        if (got != (ssize_t)(14 + 20 + 8 + sizeof(payload))) { printf("  ★長さが違う\n"); return 1; }

        /* Ethernet */
        if (memcmp(frame, "\xff\xff\xff\xff\xff\xff", 6)) { printf("  ★宛先が broadcast でない\n"); fail = 1; }
        if (memcmp(frame + 6, mac, ETHER_ADDR_LEN)) { printf("  ★送り元 MAC が interface のものでない\n"); fail = 1; }
        if (ntohs(*(uint16_t *)(frame + 12)) != ETHERTYPE_IP) { printf("  ★ethertype が IP でない\n"); fail = 1; }
        if (!fail) printf("Ethernet header ok (宛先 broadcast / 送り元 %s の MAC / type IP)\n", ifname);

        /* IP */
        {
                struct ip ip;
                memcpy(&ip, frame + 14, sizeof(ip));
                if (ip.ip_v != 4 || ip.ip_hl != 5) { printf("  ★version/ihl\n"); fail = 1; }
                if (ntohs(ip.ip_len) != 20 + 8 + sizeof(payload)) { printf("  ★ip_len\n"); fail = 1; }
                if (ip.ip_p != IPPROTO_UDP) { printf("  ★protocol\n"); fail = 1; }
                if (ntohs(ip.ip_off) != IP_DF) { printf("  ★DF が立っていない\n"); fail = 1; }
                if (packet_internet_checksum(frame + 14, 20)) { printf("  ★IP checksum が合わない\n"); fail = 1; }
                else printf("IP header ok (len=%u DF checksum 検算 0)\n", ntohs(ip.ip_len));
        }

        /* UDP */
        {
                struct udphdr u;
                memcpy(&u, frame + 34, sizeof(u));
                if (ntohs(u.uh_sport) != 68 || ntohs(u.uh_dport) != 67) { printf("  ★port\n"); fail = 1; }
                if (ntohs(u.uh_ulen) != 8 + sizeof(payload)) { printf("  ★uh_ulen\n"); fail = 1; }
                if (!u.uh_sum) { printf("  ★checksum が 0 のまま\n"); fail = 1; }
                else printf("UDP header ok (68->67 len=%u sum=0x%04x)\n", ntohs(u.uh_ulen), u.uh_sum);
        }

        if (memcmp(frame + 42, payload, sizeof(payload))) { printf("  ★payload が一致しない\n"); fail = 1; }
        else printf("payload 一致 (%zu byte)\n", sizeof(payload));

        return fail;
}

/* kernel が返すのと同じ形を組んで読ませる */
static size_t put(uint8_t *out, const uint8_t *frame, size_t n, int truncate) {
        struct bpf_hdr bh = {};
        size_t hl = BPF_WORDALIGN(sizeof(bh));
        bh.bh_hdrlen = (u_short)hl;
        bh.bh_caplen = (u_int)(truncate ? n - 1 : n);
        bh.bh_datalen = (u_int)n;
        memcpy(out, &bh, sizeof(bh));
        memcpy(out + hl, frame, bh.bh_caplen);
        return BPF_WORDALIGN(hl + bh.bh_caplen);
}

static int test_recv(void) {
        uint8_t payload[53], frame[2048], raw[4096], out[2048], mac[ETHER_ADDR_LEN];
        char ifname[IF_NAMESIZE];
        struct sockaddr_in src = { .sin_family = AF_INET, .sin_port = htons(67) };
        struct sockaddr_in dst = { .sin_family = AF_INET, .sin_port = htons(68) };
        struct packet_sockaddr_ll ha = {};
        struct sockaddr_in from = {};
        unsigned idx, i;
        size_t n = 0, off = 0;
        ssize_t got;
        int fds[2], r, fail = 0;

        if (find_if(&idx, mac, ifname)) return 77;
        for (i = 0; i < sizeof(payload); ++i) payload[i] = (uint8_t)(i * 29 + 11);
        inet_aton("192.168.1.1", &src.sin_addr);
        inet_aton("192.168.1.77", &dst.sin_addr);
        ha.sll_ifindex = (int)idx;
        ha.sll_halen = ETHER_ADDR_LEN;
        memset(ha.sll_addr, 0xaa, ETHER_ADDR_LEN);

        /* 正しい frame を一本、送信側に作らせる */
        assert(pipe(fds) == 0);
        r = packet_sendto_udp(fds[1], payload, sizeof(payload), &n, &src, &ha, &dst, 0);
        close(fds[1]);
        if (r) return 1;
        got = read(fds[0], frame, sizeof(frame));
        close(fds[0]);
        if (got <= 0) return 1;

        /* 切り詰めた一本を挟む。捨てられるはず */
        off += put(raw + off, frame, (size_t)got, 1);
        off += put(raw + off, frame, (size_t)got, 0);

        assert(pipe(fds) == 0);
        assert(write(fds[1], raw, off) == (ssize_t)off);
        close(fds[1]);

        /* BIOCGBLEN は pipe に効かないので、read の外側は測れない。
         * 分解だけを直に呼ぶ。そこが一番間違えやすい所である。 */
        got = read(fds[0], raw, sizeof(raw));
        close(fds[0]);
        if (got != (ssize_t)off) { printf("  ★pipe から全部読めない\n"); return 1; }

        r = packet_bsd_parse(raw, (size_t)got, out, sizeof(out), &n, &from);
        printf("分解 -> rc=%d 取れた payload %zu byte (期待 %zu)\n", r, n, sizeof(payload));
        if (r || n != sizeof(payload)) { printf("  ★長さが違う\n"); fail = 1; }
        else if (memcmp(out, payload, sizeof(payload))) {
                printf("  ★payload が一致しない (14 byte ずれている可能性)\n");
                printf("    先頭: 得 0x%02x / 期待 0x%02x\n", out[0], payload[0]);
                fail = 1;
        } else printf("payload 一致 (切り詰めた一本を正しく飛ばした)\n");

        if (from.sin_port != htons(67)) { printf("  ★送り元 port %u\n", ntohs(from.sin_port)); fail = 1; }
        else if (from.sin_addr.s_addr != src.sin_addr.s_addr) { printf("  ★送り元 address\n"); fail = 1; }
        else printf("送り元 %s:%u 一致\n", inet_ntoa(from.sin_addr), ntohs(from.sin_port));

        /* 壊した checksum は弾かれるはず */
        raw[off - 20] ^= 0xff;
        r = packet_bsd_parse(raw, (size_t)got, out, sizeof(out), &n, &from);
        printf("payload を壊した -> rc=%d 取れた %zu byte\n", r, n);
        if (n != 0) { printf("  ★UDP checksum の違う packet を通した\n"); fail = 1; }
        else printf("UDP checksum が合わない packet を落とした\n");

        return fail;
}

int main(void) {
        int a, b;
        printf("=== 送信 ===\n"); a = test_send();
        printf("\n=== 受信 ===\n"); b = test_recv();
        if (a == 77 || b == 77) { printf("\n=== interface が無いので測れない\n"); return 77; }
        printf("\n%s\n", (a || b) ? "=== 落ちた ===" : "=== 通った ===");
        return a || b;
}
