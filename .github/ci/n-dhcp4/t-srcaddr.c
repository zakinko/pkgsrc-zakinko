/*
 * socket_udp_send_from() が、束縛した address ではなく渡した address を
 * 送り元にするかを線で見る。
 *
 * DHCP server は、client に渡そうとしている address から答える。socket が
 * 束縛されている address ではない。Linux はこれを IP_PKTINFO と
 * struct in_pktinfo の ipi_spec_dst で言い、BSD は IP_SENDSRCADDR と素の
 * struct in_addr で言う。名前も型も違うので継ぎ目に出したが、**継ぎ目は
 * 建っただけでは踏まれない。** 上流の test-socket.c はこれを呼ぶが、Linux の
 * network namespace を使うので BSD では走らない。
 *
 * そこで tap に二つ address を載せ、片方に束縛した socket から、もう片方を
 * 送り元として一本出す。同じ tap を見ている BPF で捕まえ、IP header の
 * 送り元を読む。
 *
 * 肯定と否定を両方見る。cmsg を付けない普通の sendto() では束縛した側が
 * 出ることも確かめる。そうしないと、**検査が何も測っていなくても緑になる。**
 */
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <net/bpf.h>
#include <net/if.h>
#include <netinet/in.h>
#include <netinet/in_systm.h>
#include <netinet/ip.h>
#include <netinet/udp.h>
#include <poll.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include "socket.h"

#define BOUND "10.99.0.1"
#define CHOSEN "10.99.0.50"
#define DEST "10.99.0.99"

static int bpf_open(const char *ifname, unsigned int *lenp) {
        struct ifreq ifr;
        unsigned int len;
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
        if (ioctl(fd, BIOCGBLEN, &len) < 0) { close(fd); return -1; }
        *lenp = len;
        return fd;
}

/* 捕まえた frame のうち、UDP で DEST 宛の一本の送り元 IP を返す */
static int catch_src(int bpf, unsigned int blen, struct in_addr *out) {
        char *buf;
        ssize_t n;
        char *p, *end;

        /*
         * 時間切れを入れる。BPF の read は frame が来るまで返らないので、
         * 出したはずの一本が線に出ていないと永久に待つ。実際それで止まり、
         * 向こうの箱に process を一つ残した。
         */
        if (poll(&(struct pollfd){ .fd = bpf, .events = POLLIN }, 1, 2000) != 1) {
                printf("  (2 秒待っても線に何も出てこない)\n");
                return -1;
        }
        buf = malloc(blen);
        if (!buf)
                return -1;
        n = read(bpf, buf, blen);
        if (n <= 0) { free(buf); return -1; }
        p = buf;
        end = buf + n;
        while (p + sizeof(struct bpf_hdr) <= end) {
                struct bpf_hdr *bh = (struct bpf_hdr *)p;
                char *f = p + bh->bh_hdrlen;

                if (bh->bh_caplen >= 14 + sizeof(struct ip) + sizeof(struct udphdr)) {
                        struct ip ih;
                        memcpy(&ih, f + 14, sizeof(ih));
                        if (ih.ip_p == IPPROTO_UDP &&
                            !memcmp(&ih.ip_dst, &(struct in_addr){ inet_addr(DEST) },
                                    sizeof(struct in_addr))) {
                                *out = ih.ip_src;
                                free(buf);
                                return 0;
                        }
                }
                p += BPF_WORDALIGN(bh->bh_hdrlen + bh->bh_caplen);
        }
        free(buf);
        return -1;
}

int main(int argc, char **argv) {
        const char *ifname = argc > 1 ? argv[1] : "tap0";
        struct sockaddr_in bind_addr = {
                .sin_family = AF_INET,
                /*
                 * 67 と 68 は使わない。箱に dhcpd が居ると bind が
                 * "Address already in use" で返る。ここで測るのは送り元の
                 * 選び方だけで、port は何でもよい。
                 */
                .sin_port = htons(6767),
                .sin_addr = { inet_addr(BOUND) },
        };
        struct sockaddr_in dest = {
                .sin_family = AF_INET,
                .sin_port = htons(6768),
                .sin_addr = { inet_addr(DEST) },
        };
        struct in_addr chosen = { inet_addr(CHOSEN) };
        struct in_addr got;
        unsigned int blen;
        char devpath[64];
        int sk, bpf, tapfd, fail = 0;
        ssize_t n;

        setvbuf(stdout, NULL, _IONBF, 0);
        printf("%s: %s に束縛し、%s を送り元にして %s へ出す\n",
               ifname, BOUND, CHOSEN, DEST);

        /*
         * tap は誰も /dev/tapN を開いていないと carrier が無く、kernel は
         * そこへ送出しない。ifconfig は
         *   status: no carrier
         *   inet 10.99.0.1/24 ... flags 0x4<DETACHED>
         * と言い、sendmsg() は成功するのに線には何も出ない。
         *
         * t-wire と t-lease がこれを踏まなかったのは、あちらが BPF へ直接
         * 書いて IP stack を通らないからである。ここは通すので、開いたまま
         * 保持する。
         */
        snprintf(devpath, sizeof(devpath), "/dev/%s", ifname);
        tapfd = open(devpath, O_RDWR | O_CLOEXEC);
        if (tapfd < 0 && errno == EBUSY) {
                /* 呼ぶ側が既に握っている。carrier は立っているので構わない。 */
                printf("  %s は既に誰かが開いている (carrier は立っている)\n", devpath);
        } else if (tapfd < 0) {
                printf("  %s を開けない (%s)。carrier が立たないので測れない\n",
                       devpath, strerror(errno));
                return 77;
        }

        bpf = bpf_open(ifname, &blen);
        if (bpf < 0) { printf("  /dev/bpf を開けない (%s)\n", strerror(errno)); return 77; }

        sk = socket(AF_INET, SOCK_DGRAM, 0);
        if (sk < 0) { printf("  socket: %s\n", strerror(errno)); return 77; }
        if (bind(sk, (struct sockaddr *)&bind_addr, sizeof(bind_addr)) < 0) {
                printf("  bind %s: %s\n", BOUND, strerror(errno));
                return 77;
        }

        /*
         * 対照を先にやる。cmsg を付けない普通の sendto() すら線に出ない箱は、
         * tap へ送り出せないということで、継ぎ目の話ではない。DragonFly が
         * 実際にそうだった (run 36025998074)。そこを「落ちた」と言うと、
         * 測れなかったことを欠陥として数えることになる。
         */
        n = sendto(sk, "x", 1, 0, (struct sockaddr *)&dest, sizeof(dest));
        if (n != 1) {
                printf("★ sendto -> %zd (%s)\n", n, strerror(errno));
                return 1;
        }
        if (catch_src(bpf, blen, &got) < 0) {
                printf("  普通の sendto() すら線に出ない。この箱では測れない\n");
                return 77;
        }
        printf("  cmsg 無しの一本の送り元: %s ", inet_ntoa(got));
        if (got.s_addr == bind_addr.sin_addr.s_addr) {
                printf("(束縛した %s と一致)\n", BOUND);
        } else {
                printf("★ 期待は %s\n", BOUND);
                fail = 1;
        }

        /* 本題: 継ぎ目を通すと、渡した address が出るか */
        n = socket_udp_send_from(sk, &chosen, &dest, "x", 1);
        if (n != 1) {
                printf("★ socket_udp_send_from -> %zd (%s)\n", n, strerror(errno));
                return 1;
        }
        if (catch_src(bpf, blen, &got) < 0) {
                printf("★ 継ぎ目を通した一本が線に出ない (対照は出ている)\n");
                return 1;
        }
        printf("  継ぎ目を通した一本の送り元: %s ", inet_ntoa(got));
        if (got.s_addr == chosen.s_addr) {
                printf("(渡した %s と一致)\n", CHOSEN);
        } else {
                printf("★ 期待は %s。束縛した側が出ているなら cmsg が効いていない\n", CHOSEN);
                fail = 1;
        }

        close(sk);
        close(bpf);
        if (tapfd >= 0) close(tapfd);
        printf("\n%s\n", fail ? "=== 落ちた ===" : "=== 通った ===");
        return fail;
}
