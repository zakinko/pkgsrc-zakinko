/*
 * n_acd_bsd_read_arp() の framing だけを測る。
 *
 * /dev/bpf は root が要るので、kernel が返すのと同じ形の buffer を自分で
 * 組み、pipe から読ませる。見るのは「何本取れたか」ではなく「取れた
 * ether_arp が、詰めたものと一 byte まで同じか」である。14 byte ずれても
 * 本数は合うので、本数だけでは測ったことにならない。
 */
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/bpf.h>
#include <net/if.h>
/* OpenBSD の <netinet/if_ether.h> は struct arphdr を定義しない。 */
#include <net/if_arp.h>
#include <netinet/in.h>
#include <netinet/if_ether.h>
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


/*
 * 測る対象は本物そのもの。写しを置くと、本物を直したときに test だけが
 * 古い形を測り続けて、緑のまま意味を失う。file ごと取り込む。
 */
#include "n-acd-os-bsd.c"

/* kernel が並べるのと同じ形で一本詰める。 */
static size_t put(uint8_t *p, const struct ether_arp *arp, int truncate) {
        struct bpf_hdr bh;
        struct ether_header eh;
        size_t hdrlen = BPF_WORDALIGN(sizeof(bh));
        size_t caplen = sizeof(eh) + sizeof(*arp);

        memset(&bh, 0, sizeof(bh));
        memset(&eh, 0, sizeof(eh));
        memset(eh.ether_dhost, 0xff, ETHER_ADDR_LEN);
        eh.ether_type = htons(ETHERTYPE_ARP);

        bh.bh_hdrlen = hdrlen;
        bh.bh_datalen = caplen;
        bh.bh_caplen = truncate ? caplen - 4 : caplen;

        memcpy(p, &bh, sizeof(bh));
        memcpy(p + hdrlen, &eh, sizeof(eh));
        memcpy(p + hdrlen + sizeof(eh), arp, sizeof(*arp));
        return BPF_WORDALIGN(hdrlen + bh.bh_caplen);
}

int main(void) {
        struct ether_arp sent[3], got[8];
        uint8_t buf[4096], raw[4096];
        size_t lens[8];
        size_t off = 0, n = 0;
        int fds[2], r, i, fail = 0;

        /* 三本。中身は全部違う値で埋める。 */
        for (i = 0; i < 3; ++i)
                memset(sent + i, 0x11 * (i + 1), sizeof(sent[i]));

        off += put(raw + off, sent + 0, 0);
        off += put(raw + off, sent + 1, 1);   /* 切り詰められた一本。捨てられるはず */
        off += put(raw + off, sent + 2, 0);

        assert(pipe(fds) == 0);
        assert(write(fds[1], raw, off) == (ssize_t)off);
        close(fds[1]);

        r = n_acd_bsd_read_arp(fds[0], buf, sizeof(buf), got, lens, 8, &n);
        printf("rc=%d 取れた本数=%zu (期待 2)\n", r, n);
        if (r != 0 || n != 2) { printf("  ★本数が合わない\n"); fail = 1; }

        if (n >= 1 && memcmp(got + 0, sent + 0, sizeof(sent[0])) != 0) {
                printf("  ★一本目が一致しない\n"); fail = 1;
        } else if (n >= 1) printf("  一本目 一致\n");

        if (n >= 2 && memcmp(got + 1, sent + 2, sizeof(sent[2])) != 0) {
                printf("  ★二本目が一致しない (切り詰めを飛ばせていない可能性)\n");
                printf("    先頭 byte: 得 0x%02x / 期待 0x%02x\n",
                       ((uint8_t *)(got + 1))[0], ((uint8_t *)(sent + 2))[0]);
                fail = 1;
        } else if (n >= 2) printf("  二本目 一致 (切り詰めを正しく飛ばした)\n");

        printf("%s\n", fail ? "=== 落ちた ===" : "=== 通った ===");
        return fail;
}
