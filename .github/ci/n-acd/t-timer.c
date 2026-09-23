/* Does the timer seam fire at the deadline it was given, and does the nested
 * queue wake the outer poller?  Measured, not assumed. */
#include <errno.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/event.h>
#include "n-acd-os.h"

static uint64_t now_ns(int clock) {
        struct timespec t;
        clock_gettime(clock, &t);
        return (uint64_t)t.tv_sec * 1000000000ULL + (uint64_t)t.tv_nsec;
}

static int one(int tfd, int pfd, int clock, unsigned ms) {
        uint64_t t0, fired;
        struct kevent ev;
        struct timespec to = { .tv_sec = 5 };
        int r;

        t0 = now_ns(clock);
        r = n_acd_os_timer_set(tfd, clock, t0 + (uint64_t)ms * 1000000ULL);
        if (r) { printf("set: %d\n", r); return 1; }

        r = kevent(pfd, NULL, 0, &ev, 1, &to);
        fired = now_ns(clock);
        if (r != 1) { printf("  %4ums: outer kevent r=%d (%s)\n", ms, r, strerror(errno)); return 1; }
        if ((int)ev.ident != tfd) { printf("  wrong ident\n"); return 1; }

        n_acd_os_timer_read(tfd);
        {
                long long d = (long long)(fired - t0) / 1000000;
                long long err = d - (long long)ms;
                printf("  %4ums 指定 -> %4lldms で起床 (誤差 %+lldms) %s\n",
                       ms, d, err, (err >= -2 && err <= 60) ? "ok" : "NG");
                return !(err >= -2 && err <= 60);
        }
}

int main(void) {
        struct kevent ev;
        int tfd, pfd, clock, bad = 0;

        if (n_acd_os_timer_new(&tfd, &clock)) { printf("timer_new failed\n"); return 1; }
        pfd = kqueue();
        EV_SET(&ev, tfd, EVFILT_READ, EV_ADD | EV_ENABLE, 0, 0, NULL);
        if (kevent(pfd, &ev, 1, NULL, 0, NULL) < 0) { perror("nest"); return 1; }

        printf("clock=%d tfd=%d (外側 kqueue=%d に入れ子)\n", clock, tfd, pfd);
        bad += one(tfd, pfd, clock, 50);
        bad += one(tfd, pfd, clock, 200);
        bad += one(tfd, pfd, clock, 1000);

        /* A deadline already in the past must fire at once, not disarm. */
        {
                struct timespec to = { .tv_sec = 2 };
                uint64_t t0 = now_ns(clock);
                n_acd_os_timer_set(tfd, clock, t0 - 1000000000ULL);
                if (kevent(pfd, &ev, 0, &ev, 1, &to) == 1) {
                        printf("  過去の deadline -> %lldms で起床 ok\n",
                               (long long)(now_ns(clock) - t0) / 1000000);
                        n_acd_os_timer_read(tfd);
                } else { printf("  過去の deadline -> 焼けない NG\n"); bad++; }
        }

        /* Zero must disarm: the outer poller must then time out. */
        {
                struct timespec to = { .tv_nsec = 300000000 };
                n_acd_os_timer_set(tfd, clock, 0);
                if (kevent(pfd, NULL, 0, &ev, 1, &to) == 0)
                        printf("  0 -> 解除され、外側は timeout ok\n");
                else { printf("  0 -> 解除できていない NG\n"); bad++; }
        }

        printf(bad ? "=== NG %d\n" : "=== 全部通った\n", bad);
        return !!bad;
}
