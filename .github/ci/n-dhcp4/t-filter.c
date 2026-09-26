/*
 * BPF filter を Linux 版から BSD 版へ移すとき、offset を全部 14 ずらす。
 * AF_PACKET/SOCK_DGRAM は link header を剥がして IP から渡すが、BPF device
 * は Ethernet header から渡すためである。
 *
 * ここを間違えると「全部通る」か「全部落ちる」になり、どちらも静かである。
 * 建てただけでは分からないし、実機で一度動いたことも証明にならない (正しい
 * packet しか来なければ、全部通す filter は正しく見える)。
 *
 * libpcap の bpf_filter() は kernel と同じ interpreter なので、両方の filter
 * を同じ packet に通して、判定が一致するかを見る。写しではなく本物の
 * interpreter である。
 */
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/in_systm.h>
#include <netinet/ip.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

/*
 * 測る対象は写しではない。当て物が置く実物を丸ごと取り込む。
 * <net/bpf.h> はこの中で読まれる。<pcap/bpf.h> は同じ名前を別に定義するので
 * 読まない。bpf_filter() だけ自分で宣言する — 実体は libpcap に在り、あれは
 * kernel と同じ interpreter である。
 */
#include "n-dhcp4-socket-bsd.c"

u_int bpf_filter(const struct bpf_insn *, const u_char *, u_int, u_int);

#define ETHER_HDR_LEN_ (14)
#define IP_HDR_LEN_    (20)
#define UDP_HDR_LEN_   (8)
#define DHCP_MIN_      (240)

#define OFF_OP                      (0)
#define OFF_MAGIC                   (236)

/* IP header の中の位置 (struct iphdr / struct ip で同じ) */
#define IP_OFF_PROTOCOL (9)
#define IP_OFF_FRAG     (6)
#define UDP_OFF_DEST    (2)

/* ---- Linux 版。上流そのままの並び。packet は IP から始まる ---- */
static struct bpf_insn filter_linux[] = {
        BPF_STMT(BPF_LD + BPF_B + BPF_ABS, IP_OFF_PROTOCOL),
        BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, IPPROTO_UDP, 1, 0),
        BPF_STMT(BPF_RET + BPF_K, 0),

        BPF_STMT(BPF_LD + BPF_H + BPF_ABS, IP_OFF_FRAG),
        BPF_STMT(BPF_ALU + BPF_AND + BPF_K, IP_MF | IP_OFFMASK),
        BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, 0, 1, 0),
        BPF_STMT(BPF_RET + BPF_K, 0),

        BPF_STMT(BPF_LDX + BPF_B + BPF_MSH, 0),
        BPF_STMT(BPF_LD + BPF_W + BPF_LEN, 0),
        BPF_STMT(BPF_ALU + BPF_SUB + BPF_X, 0),
        BPF_JUMP(BPF_JMP + BPF_JGE + BPF_K, UDP_HDR_LEN_ + DHCP_MIN_, 1, 0),
        BPF_STMT(BPF_RET + BPF_K, 0),

        BPF_STMT(BPF_LD + BPF_H + BPF_IND, UDP_OFF_DEST),
        BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, N_DHCP4_NETWORK_CLIENT_PORT, 1, 0),
        BPF_STMT(BPF_RET + BPF_K, 0),

        BPF_STMT(BPF_LD + BPF_W + BPF_K, UDP_HDR_LEN_),
        BPF_STMT(BPF_ALU + BPF_ADD + BPF_X, 0),
        BPF_STMT(BPF_MISC + BPF_TAX, 0),

        BPF_STMT(BPF_LD + BPF_B + BPF_IND, OFF_OP),
        BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, N_DHCP4_OP_BOOTREPLY, 1, 0),
        BPF_STMT(BPF_RET + BPF_K, 0),

        BPF_STMT(BPF_LD + BPF_W + BPF_IND, OFF_MAGIC),
        BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, N_DHCP4_MESSAGE_MAGIC, 1, 0),
        BPF_STMT(BPF_RET + BPF_K, 0),

        BPF_STMT(BPF_RET + BPF_K, 65535),
};

/*
 * BSD 版は写しではない。当て物が置く n-dhcp4-socket-bsd.c を丸ごと取り込んで、
 * その中の n_dhcp4_bsd_client_filter をそのまま測る。写しを置くと、本物を
 * 直した日に緑のまま意味を失う。
 *
 * Linux 版だけは写しである。あちらは上流の file で、こちらは触らない。BSD で
 * は建たないので取り込めない。上流が filter を変えたらここが古くなるので、
 * 版を上げるときは目で突き合わせる。
 */
#define filter_bsd n_dhcp4_bsd_client_filter

/* Ethernet + IP + UDP + DHCP を一本組む */
static size_t build(uint8_t *f, int op, uint32_t magic, uint16_t dport,
                    uint8_t proto, uint16_t frag, uint16_t ethertype, size_t dhcplen) {
        size_t n = E + IP_HDR_LEN_ + UDP_HDR_LEN_ + dhcplen;
        uint16_t v;
        memset(f, 0, n);
        memset(f, 0xff, 6);
        memset(f + 6, 0xaa, 6);
        v = htons(ethertype); memcpy(f + 12, &v, 2);
        f[E + 0] = 0x45;
        v = htons((uint16_t)(IP_HDR_LEN_ + UDP_HDR_LEN_ + dhcplen)); memcpy(f + E + 2, &v, 2);
        v = htons(frag); memcpy(f + E + IP_OFF_FRAG, &v, 2);
        f[E + IP_OFF_PROTOCOL] = proto;
        v = htons(67); memcpy(f + E + IP_HDR_LEN_ + 0, &v, 2);
        v = htons(dport); memcpy(f + E + IP_HDR_LEN_ + UDP_OFF_DEST, &v, 2);
        v = htons((uint16_t)(UDP_HDR_LEN_ + dhcplen)); memcpy(f + E + IP_HDR_LEN_ + 4, &v, 2);
        if (dhcplen > 0) f[E + IP_HDR_LEN_ + UDP_HDR_LEN_ + OFF_OP] = (uint8_t)op;
        if (dhcplen >= OFF_MAGIC + 4) {
                uint32_t m = htonl(magic);
                memcpy(f + E + IP_HDR_LEN_ + UDP_HDR_LEN_ + OFF_MAGIC, &m, 4);
        }
        return n;
}

struct tc { const char *name; int op; uint32_t magic; uint16_t dport;
            uint8_t proto; uint16_t frag; uint16_t ethertype; size_t dhcplen; int want; };

int main(void) {
        static const struct tc cases[] = {
        { "正しい DHCP 応答",   2, N_DHCP4_MESSAGE_MAGIC, 68, IPPROTO_UDP, 0, ETHERTYPE_IP, DHCP_MIN_, 1 },
        { "port が違う",        2, N_DHCP4_MESSAGE_MAGIC, 67, IPPROTO_UDP, 0, ETHERTYPE_IP, DHCP_MIN_, 0 },
        { "op が BOOTREQUEST",  1, N_DHCP4_MESSAGE_MAGIC, 68, IPPROTO_UDP, 0, ETHERTYPE_IP, DHCP_MIN_, 0 },
        { "magic が違う",       2, 0xdeadbeef,            68, IPPROTO_UDP, 0, ETHERTYPE_IP, DHCP_MIN_, 0 },
        { "UDP でない",         2, N_DHCP4_MESSAGE_MAGIC, 68, IPPROTO_TCP, 0, ETHERTYPE_IP, DHCP_MIN_, 0 },
        { "断片化している",     2, N_DHCP4_MESSAGE_MAGIC, 68, IPPROTO_UDP, 0x2000, ETHERTYPE_IP, DHCP_MIN_, 0 },
        { "短すぎる",           2, N_DHCP4_MESSAGE_MAGIC, 68, IPPROTO_UDP, 0, ETHERTYPE_IP, 100, 0 },
        { "長い (options 付き)",2, N_DHCP4_MESSAGE_MAGIC, 68, IPPROTO_UDP, 0, ETHERTYPE_IP, DHCP_MIN_ + 60, 1 },
        };
        uint8_t frame[2048];
        unsigned i;
        int fail = 0;

        printf("%-22s %8s %8s %6s\n", "場合", "Linux", "BSD", "期待");
        for (i = 0; i < sizeof(cases) / sizeof(cases[0]); ++i) {
                const struct tc *t = &cases[i];
                size_t n = build(frame, t->op, t->magic, t->dport, t->proto,
                                 t->frag, t->ethertype, t->dhcplen);
                u_int rl, rb;

                /* Linux は IP から。BSD は Ethernet から。 */
                rl = bpf_filter(filter_linux, frame + E, (u_int)(n - E), (u_int)(n - E));
                rb = bpf_filter(filter_bsd, frame, (u_int)n, (u_int)n);

                printf("%-22s %8s %8s %6s%s\n", t->name,
                       rl ? "通す" : "落とす", rb ? "通す" : "落とす",
                       t->want ? "通す" : "落とす",
                       (!!rl == t->want && !!rb == t->want) ? "" : "  ★");
                if (!!rl != t->want || !!rb != t->want) fail = 1;
        }

        /* Ethernet type が IP でない場合は BSD 側にしか無い検査 */
        {
                size_t n = build(frame, 2, N_DHCP4_MESSAGE_MAGIC, 68, IPPROTO_UDP, 0, 0x86dd, DHCP_MIN_);
                u_int rb = bpf_filter(filter_bsd, frame, (u_int)n, (u_int)n);
                printf("%-22s %8s %8s %6s%s\n", "IPv6 の ethertype", "-",
                       rb ? "通す" : "落とす", "落とす", rb ? "  ★" : "");
                if (rb) fail = 1;
        }

        printf("\n%s\n", fail ? "=== 落ちた ===" : "=== 二つの filter は同じ判定をした ===");
        return fail;
}
