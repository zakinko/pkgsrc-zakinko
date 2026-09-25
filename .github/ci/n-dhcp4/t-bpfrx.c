/*
 * BPF へ書いた frame を、同じ interface の別の BPF が読めるか。filter を
 * 入れた場合と入れない場合で分ける。
 *
 * t-lease が FreeBSD と GhostBSD で止まっていた。偽 server は client の
 * DISCOVER を読めている (BPF -> BPF は片方向では動いている) のに、返した
 * OFFER を client が読めない。NetBSD と DragonFly では通る。
 *
 * 考えられるのは二つで、線に出ていないのか、こちらの filter が落としている
 * のか。t-filter は libpcap の interpreter に合成 packet を通して Linux 版と
 * 判定が一致することを見ているが、それは**実際に kernel が返す frame**を
 * 通した話ではない。どちらなのかを分けないと、直す場所が決まらない。
 *
 *   filter 無し  … 線に出ているか (BPF から BPF へ届くか)
 *   filter あり  … 当て物が置く実物の filter が通すか
 *
 * 実物を取り込む。写しを置くと本物を直した日に意味を失う。
 */
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <sys/event.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/bpf.h>
#include <net/if.h>
#include <netinet/in.h>
#include <netinet/in_systm.h>
#include <netinet/ip.h>
#include <netinet/udp.h>

#include "n-dhcp4-socket-bsd.c"

/* E (= 14, Ethernet header の長さ) は取り込んだ side が定義している */

static int bpf_open(const char *ifname, unsigned int *lenp) {
        struct ifreq ifr;
        int fd, on = 1, i;

        fd = open("/dev/bpf", O_RDWR | O_CLOEXEC);
        if (fd < 0 && (errno == ENOENT || errno == EBUSY)) {
                char path[sizeof("/dev/bpf4294967295")];
                for (i = 0; i < 256; ++i) {
                        snprintf(path, sizeof(path), "/dev/bpf%u", i);
                        fd = open(path, O_RDWR | O_CLOEXEC);
                        if (fd >= 0 || (errno != EBUSY && errno != ENOENT))
                                break;
                }
        }
        if (fd < 0)
                return -1;
        memset(&ifr, 0, sizeof(ifr));
        snprintf(ifr.ifr_name, sizeof(ifr.ifr_name), "%s", ifname);
        if (ioctl(fd, BIOCSETIF, &ifr) < 0) { close(fd); return -1; }
        if (ioctl(fd, BIOCIMMEDIATE, &on) < 0) { close(fd); return -1; }
        if (ioctl(fd, BIOCSHDRCMPLT, &on) < 0) { close(fd); return -1; }
        if (lenp && ioctl(fd, BIOCGBLEN, lenp) < 0) { close(fd); return -1; }
        return fd;
}

/* DHCP の OFFER を一本。server 67 -> client 68 の broadcast。 */
static size_t build_offer(uint8_t *f) {
        size_t dhcplen = 244;
        size_t n = E + 20 + 8 + dhcplen;
        uint16_t v;

        memset(f, 0, n);
        memset(f, 0xff, 6);                     /* 宛先 broadcast */
        memset(f + 6, 0xaa, 6);                 /* 送り元 */
        v = htons(0x0800); memcpy(f + 12, &v, 2);

        f[E + 0] = 0x45;                        /* IPv4, ihl 5 */
        v = htons((uint16_t)(20 + 8 + dhcplen)); memcpy(f + E + 2, &v, 2);
        f[E + 8] = 64;                          /* ttl */
        f[E + 9] = IPPROTO_UDP;
        /* 送り元 10.99.0.1 宛先 255.255.255.255 */
        f[E + 12] = 10; f[E + 13] = 99; f[E + 14] = 0; f[E + 15] = 1;
        memset(f + E + 16, 0xff, 4);

        v = htons(67); memcpy(f + E + 20 + 0, &v, 2);
        v = htons(68); memcpy(f + E + 20 + 2, &v, 2);
        v = htons((uint16_t)(8 + dhcplen)); memcpy(f + E + 20 + 4, &v, 2);

        f[E + 28] = 2;                          /* op = BOOTREPLY */
        f[E + 29] = 1;                          /* htype */
        f[E + 30] = 6;                          /* hlen */
        /* magic 0x63825363 は DHCP 固定部の 236 byte 目 */
        f[E + 28 + 236] = 0x63; f[E + 28 + 237] = 0x82;
        f[E + 28 + 238] = 0x53; f[E + 28 + 239] = 0x63;
        f[E + 28 + 240] = 53; f[E + 28 + 241] = 1; f[E + 28 + 242] = 2; /* OFFER */
        f[E + 28 + 243] = 255;
        return n;
}

static int try_once(int rd, unsigned int blen, int wr, const char *what) {
        uint8_t frame[1500];
        size_t n = build_offer(frame);
        char *buf;
        ssize_t r;
        int got = 0;

        /* 前の回の残りを捨てる */
        buf = malloc(blen);
        if (!buf) return -1;
        while (poll(&(struct pollfd){ .fd = rd, .events = POLLIN }, 1, 0) == 1)
                (void)read(rd, buf, blen);

        if (write(wr, frame, n) != (ssize_t)n) {
                printf("  %s: 書けない (%s)\n", what, strerror(errno));
                free(buf);
                return -1;
        }
        if (poll(&(struct pollfd){ .fd = rd, .events = POLLIN }, 1, 2000) == 1) {
                r = read(rd, buf, blen);
                if (r > 0)
                        got = 1;
        }
        printf("  %-12s %s\n", what, got ? "届いた" : "届かない");
        free(buf);
        return got;
}

/* 同じことを kqueue で待って見る */
static int kqueue_once(int rd, unsigned int blen, int wr) {
        uint8_t frame[1500];
        size_t n = build_offer(frame);
        struct kevent kev;
        struct timespec ts = { .tv_sec = 2 };
        char *buf;
        int kq, got = 0;

        buf = malloc(blen);
        if (!buf)
                return -1;
        while (poll(&(struct pollfd){ .fd = rd, .events = POLLIN }, 1, 0) == 1)
                (void)read(rd, buf, blen);

        kq = kqueue();
        if (kq < 0) { printf("  kqueue: %s\n", strerror(errno)); free(buf); return -1; }
        EV_SET(&kev, rd, EVFILT_READ, EV_ADD | EV_ENABLE, 0, 0, NULL);
        if (kevent(kq, &kev, 1, NULL, 0, NULL) < 0) {
                printf("  kevent(EV_ADD): %s\n", strerror(errno));
                close(kq); free(buf); return -1;
        }
        if (write(wr, frame, n) != (ssize_t)n) {
                printf("  kqueue: 書けない (%s)\n", strerror(errno));
                close(kq); free(buf); return -1;
        }
        if (kevent(kq, NULL, 0, &kev, 1, &ts) == 1)
                got = 1;
        printf("  %-12s %s\n", "kqueue", got ? "報せた" : "報せない");
        /* 報せなくても中身は届いているかを見る */
        if (!got && poll(&(struct pollfd){ .fd = rd, .events = POLLIN }, 1, 0) == 1)
                printf("               (poll では読める。kqueue だけが黙っている)\n");
        close(kq);
        free(buf);
        return got;
}

int main(int argc, char **argv) {
        const char *ifname = argc > 1 ? argv[1] : "tap0";
        struct bpf_program prog = {
                .bf_len = sizeof(n_dhcp4_bsd_client_filter) /
                          sizeof(n_dhcp4_bsd_client_filter[0]),
                .bf_insns = n_dhcp4_bsd_client_filter,
        };
        unsigned int blen;
        int rd, wr, a, b, c;

        setvbuf(stdout, NULL, _IONBF, 0);
        printf("%s で BPF から BPF へ DHCP OFFER を一本\n", ifname);

        wr = bpf_open(ifname, NULL);
        rd = bpf_open(ifname, &blen);
        if (wr < 0 || rd < 0) {
                printf("  /dev/bpf を開けない (%s)\n", strerror(errno));
                return 77;
        }

        a = try_once(rd, blen, wr, "filter 無し");

        if (ioctl(rd, BIOCSETF, &prog) < 0) {
                printf("  BIOCSETF: %s\n", strerror(errno));
                return 1;
        }
        b = try_once(rd, blen, wr, "filter あり");

        /*
         * ここまでは poll(2) で見ている。n-dhcp4 の client は dispatch の中で
         * kqueue を通るので、kqueue が BPF の読み可を報せるかは別の話である。
         * FreeBSD と GhostBSD で t-lease だけが止まり、上の二つが届くのなら、
         * 残るのはここしかない。
         */
        c = kqueue_once(rd, blen, wr);

        close(rd);
        close(wr);

        if (a < 0 || b < 0 || c < 0)
                return 1;
        if (!a) {
                printf("\n=== 線に出ていない。filter の話ではない ===\n");
                return 77;   /* この箱では BPF から BPF へ届かない */
        }
        if (!b) {
                printf("\n=== 線には出ているが filter が落としている ===\n");
                return 1;
        }
        if (!c) {
                printf("\n=== poll では読めるが kqueue が報せない ===\n");
                return 1;
        }
        printf("\n=== 通った ===\n");
        return 0;
}
