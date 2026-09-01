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

	/* 起動して画面を描くまで少し待ってから鍵を送る。 */
	sleep(2);
	for (i = 0; argv[3][i] && argv[3][i+1]; i += 2) {
		char h[3] = { argv[3][i], argv[3][i+1], 0 };
		unsigned char c = (unsigned char)strtol(h, NULL, 16);
		if (write(master, &c, 1) != 1)
			break;
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
