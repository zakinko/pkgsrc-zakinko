/*
 * 全画面 editor を pty の向こうで走らせて、画面に出たものを file へ落とす。
 *
 *	ptydrive <out> <seconds> <keys-in-hex> <cmd> [args...]
 *
 * script(1) でやろうとしたが、NetBSD のそれは -c を付けても記録が空だった。
 * 掴めないものを回避で誤魔化すより、openpty(3) を直に呼ぶほうが短い。
 *
 * 時限は alarm(2) で持つ。editor が終わらなくても必ず降りる。NetBSD の base に
 * timeout(1) は無く、外から pkill を撃つと模様が広すぎて他人を巻き込む。
 * 実際それで自分の見張りを殺した。
 */
#include <sys/types.h>
#include <sys/wait.h>
#include <err.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <poll.h>
#include <termios.h>
#include <unistd.h>
/*
 * openpty(3) と login_tty(3) の在処は libc で違う。BSD と macOS は
 * <util.h>、glibc は <pty.h> と <utmp.h> である。Debian の job が
 * 「駆動器を組めなかった。動作は見ていない」で終わったのはこれだった。
 * package は建っていて、動かす側だけが移植性を欠いていた。
 */
#if defined(__linux__)
#include <pty.h>
#include <utmp.h>
#elif defined(__FreeBSD__) || defined(__DragonFly__)
#include <libutil.h>
#else
#include <util.h>
#endif

static void on_alarm(int sig) { (void)sig; _exit(9); }

int
main(int argc, char **argv)
{
	int master, n, i;
	pid_t pid;
	char buf[4096];
	int outfd;
	struct winsize ws;

	if (argc < 5)
		errx(1, "usage: ptydrive <out> <sec> <hexkeys> <cmd> [args]");

	ws.ws_row = 25; ws.ws_col = 80; ws.ws_xpixel = 0; ws.ws_ypixel = 0;
	if (openpty(&master, &n, NULL, NULL, &ws) == -1)
		err(1, "openpty");

	if ((pid = fork()) == -1)
		err(1, "fork");
	if (pid == 0) {
		close(master);
		login_tty(n);
		execv(argv[4], &argv[4]);
		_exit(127);
	}
	close(n);

	/*
	 * 記録は鍵を送る前に開いて、read したそばから write(2) で落とす。
	 * 最初 stdio で溜めて最後に fclose していたが、時限で _exit したとき
	 * 転写が丸ごと消えて 0 バイトになった。降りたときこそ画面が要る。
	 */
	if ((outfd = open(argv[1], O_WRONLY|O_CREAT|O_TRUNC, 0644)) == -1)
		err(1, "%s", argv[1]);
	signal(SIGALRM, on_alarm);
	alarm((unsigned)atoi(argv[2]));

	/*
	 * 鍵を送るのは、editor が読める状態になったのを見てからにする。
	 *
	 * 時間で待つ (sleep(2)) と遅い箱で足りない。出力が途切れたことで
	 * 待つと、pty の癖に振られる。NetBSD の pty は相手が slave を開く前に
	 * poll が POLLHUP を返すことがあり、read が 0 か -1 になって、何も
	 * 出ていないのに「途切れた」と読んで即座に送っていた。三回書き換えて
	 * 三回とも同じ 3142 バイトで止まったのは、そのせいだと見ている。
	 *
	 * 印を待つ。PTYDRIVE_READY に文字列が在れば、それが出力に現れるまで
	 * 待つ。editor が menu を描き終えて主 loop に入った印になる。無ければ
	 * 出力が途切れるまで、で妥協する。read が 0 か -1 でも子が生きている
	 * なら諦めず、少し待って読み直す。
	 */
	{
		struct pollfd pfd;
		char b[4096];
		static char seen[65536];
		size_t sl = 0;
		const char *ready = getenv("PTYDRIVE_READY");
		int got = 0, quiet = 0, spent = 0, idle = 0, found = 0;

		if (ready && !*ready)
			ready = NULL;
		pfd.fd = master;
		pfd.events = POLLIN;
		/* 印が出るまで、あるいは 30 秒。印が無ければ静かになるまで。 */
		while (spent < 60) {
			int r = poll(&pfd, 1, 500);

			spent++;
			if (r > 0) {
				n = read(master, b, sizeof(b));
				if (n <= 0) {
					if (kill(pid, 0) == 0) { usleep(100000); continue; }
					break;
				}
				(void)write(outfd, b, (size_t)n);
				if (sl + (size_t)n < sizeof(seen)) {
					memcpy(seen + sl, b, (size_t)n);
					sl += (size_t)n;
					seen[sl] = 0;
				}
				got += n;
				quiet = 0;
				if (ready && !found && strstr(seen, ready))
					found = 1;
			} else if (r == 0) {
				if (found) {
					if (++quiet >= 2) break;     /* 印が出て 1 秒静か */
				} else if (!ready && got > 0) {
					if (++quiet >= 3) break;     /* 印なし: 1.5 秒静か */
				} else if (got == 0) {
					if (++idle > 40) break;      /* 20 秒何も出ない */
				}
			} else
				break;
		}
		if (ready && !found)
			(void)write(2, "ptydrive: ready marker not seen\n", 32);
	}

	/* 鍵は一つずつ。送るたびに画面を吸わないと pty が詰まる。 */
	for (i = 0; argv[3][i] && argv[3][i+1]; i += 2) {
		char h[3] = { argv[3][i], argv[3][i+1], 0 };
		unsigned char c = (unsigned char)strtol(h, NULL, 16);
		struct pollfd pfd;
		char b[4096];

		if (write(master, &c, 1) != 1)
			break;
		pfd.fd = master;
		pfd.events = POLLIN;
		while (poll(&pfd, 1, 200) > 0) {
			n = read(master, b, sizeof(b));
			if (n <= 0)
				break;
			(void)write(outfd, b, (size_t)n);
		}
		/*
		 * 間は捨てられない。吸うだけにして usleep を外したら、出力の
		 * 無い鍵が続くときに間が消えて、NetBSD も FreeBSD も GhostBSD も
		 * 一つも効かなくなった。それまで通っていた箱を全部落としている。
		 * 吸うのは pty を詰まらせないためで、待つ代わりではない。
		 */
		usleep(200000);
	}

	while ((n = read(master, buf, sizeof(buf))) > 0)
		(void)write(outfd, buf, (size_t)n);

	alarm(0);
	{
		int st = 0;
		if (waitpid(pid, &st, WNOHANG) == pid && WIFEXITED(st))
			return WEXITSTATUS(st) == 0 ? 0 : 20 + WEXITSTATUS(st);
	}
	return 0;
}
