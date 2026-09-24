/*
 * 建ったことでも、生成できたことでもなく、「ARP を撃って答えが返り、
 * state machine がそれを USED と言うか」を測る。
 *
 * 在る address (gateway) を探らせて USED が返れば、送信・BPF filter・
 * 受信・framing・timer・state machine が一本に繋がっている。
 * 無い address を探らせて READY が返れば、待ちと再送も回っている。
 */
#include <arpa/inet.h>
#include <errno.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/event.h>
#include <sys/socket.h>
#include <time.h>
#include <unistd.h>
#include "n-acd.h"

static const char *evname(unsigned int e) {
        switch (e) {
        case N_ACD_EVENT_READY:  return "READY (誰も使っていない)";
        case N_ACD_EVENT_USED:   return "USED (既に使われている)";
        case N_ACD_EVENT_DEFENDED: return "DEFENDED";
        case N_ACD_EVENT_CONFLICT: return "CONFLICT";
        case N_ACD_EVENT_DOWN:   return "DOWN";
        default: return "?";
        }
}

static int run(NAcd *acd, const char *label, const char *ip, unsigned secs,
               unsigned *gotp, int *havep) {
        NAcdProbeConfig *pc = NULL;
        NAcdProbe *probe = NULL;
        struct in_addr addr;
        struct timespec t0, now;
        int fd, kq, r;

        *gotp = 0;
        *havep = 0;
        if (!inet_aton(ip, &addr)) return 1;
        if (n_acd_probe_config_new(&pc)) return 1;
        n_acd_probe_config_set_ip(pc, addr);
        n_acd_probe_config_set_timeout(pc, 1000);

        r = n_acd_probe(acd, &probe, pc);
        n_acd_probe_config_free(pc);
        if (r) { printf("  %s: n_acd_probe -> %d\n", label, r); return 1; }

        n_acd_get_fd(acd, &fd);
        kq = kqueue();
        {
                struct kevent ev;
                EV_SET(&ev, fd, EVFILT_READ, EV_ADD | EV_ENABLE, 0, 0, NULL);
                kevent(kq, &ev, 1, NULL, 0, NULL);
        }

        clock_gettime(CLOCK_MONOTONIC, &t0);
        for (;;) {
                struct kevent ev;
                struct timespec to = { .tv_nsec = 200000000 };
                NAcdEvent *e;

                kevent(kq, NULL, 0, &ev, 1, &to);

                do {
                        r = n_acd_dispatch(acd);
                } while (r == N_ACD_E_PREEMPTED);
                if (r) { printf("  %s: dispatch -> %d\n", label, r); break; }

                for (;;) {
                        if (n_acd_pop_event(acd, &e) || !e) break;
                        printf("  %s: %s\n", label, evname(e->event));
                        *gotp = e->event;
                        *havep = 1;
                }
                if (*havep) break;

                clock_gettime(CLOCK_MONOTONIC, &now);
                if ((unsigned)(now.tv_sec - t0.tv_sec) >= secs) {
                        printf("  %s: %u 秒で何も来ない\n", label, secs);
                        break;
                }
        }

        close(kq);
        n_acd_probe_free(probe);
        return 0;
}

int main(int argc, char **argv) {
        struct ifaddrs *ifa, *i;
        NAcdConfig *c = NULL;
        NAcd *acd = NULL;
        uint8_t mac[6];
        unsigned idx = 0, got;
        int r, have = 0, fail = 0;

        if (argc < 3) { printf("使い方: t-probe <在る address> <無い address>\n"); return 2; }

        if (getifaddrs(&ifa)) return 1;
        for (i = ifa; i; i = i->ifa_next) {
                struct sockaddr_dl *dl = (struct sockaddr_dl *)i->ifa_addr;
                if (!dl || dl->sdl_family != AF_LINK || dl->sdl_alen != 6) continue;
                if (!(i->ifa_flags & IFF_UP) || (i->ifa_flags & IFF_LOOPBACK)) continue;
                memcpy(mac, LLADDR(dl), 6);
                idx = if_nametoindex(i->ifa_name);
                printf("interface %s (index %u)\n", i->ifa_name, idx);
                break;
        }
        freeifaddrs(ifa);
        if (!idx) return 77;

        if (n_acd_config_new(&c)) return 1;
        n_acd_config_set_ifindex(c, (int)idx);
        n_acd_config_set_transport(c, N_ACD_TRANSPORT_ETHERNET);
        n_acd_config_set_mac(c, mac, sizeof(mac));

        r = n_acd_new(&acd, c);
        n_acd_config_free(c);
        if (r) { printf("n_acd_new -> %d (%s)\n", r, strerror(-r)); return 77; }

        /*
         * argv[1] が空なら「在る address」の側は測らない。qemu の
         * user-mode network では gateway が本物ではなく、spa=0 の ARP に
         * 答えないので、そこに期待を置いても測っているのは qemu である。
         */
        if (argv[1][0]) {
                printf("--- 在る address %s を探る (USED を期待)\n", argv[1]);
                run(acd, argv[1], argv[1], 12, &got, &have);
                if (!have || got != N_ACD_EVENT_USED) { printf("  ★期待と違う\n"); fail = 1; }
        }

        printf("--- 無い address %s を探る (READY を期待)\n", argv[2]);
        run(acd, argv[2], argv[2], 20, &got, &have);
        if (!have || got != N_ACD_EVENT_READY) { printf("  ★期待と違う\n"); fail = 1; }

        n_acd_unref(acd);
        printf("%s\n", fail ? "=== 落ちた ===" : "=== 通った ===");
        return fail;
}
