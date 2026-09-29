/*
 * 32bit の guest で readdir() が dir を最後まで読めるかを測る。
 *
 * mipsle の bootstrap が「no system rules (sys.mk)」で止まった。sys.mk は
 * share/mk に在り、bmake の .SYSPATH もその dir を指していた。bmake は
 * dir を readdir() で一覧にして探すので、一覧が途中で切れれば「無い」になる。
 * 32bit の readdir() は d_ino か d_off が 32bit を超えると EOVERFLOW を返す。
 * 以前の probe は ls で数えたが、ls は readdir64 を使うのでこの形を測れない。
 *
 * _FILE_OFFSET_BITS を付けずに組んだ物と付けて組んだ物を同じ dir に撃ち、
 * 読めた件数と、止まったときの errno を出す。
 */
#include <dirent.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

int
main(int argc, char **argv)
{
	for (int i = 1; i < argc; i++) {
		DIR *d = opendir(argv[i]);
		if (d == NULL) {
			printf("%s: opendir: %s\n", argv[i], strerror(errno));
			continue;
		}
		int n = 0, found = 0;
		struct dirent *e;
		errno = 0;
		while ((e = readdir(d)) != NULL) {
			n++;
			if (strcmp(e->d_name, "sys.mk") == 0)
				found = 1;
			errno = 0;
		}
		int err = errno;
		printf("%s: sizeof(off_t)=%u entries=%d sys.mk=%s end=%s\n",
		    argv[i], (unsigned)sizeof(off_t), n, found ? "yes" : "no",
		    err ? strerror(err) : "ok");
		closedir(d);
	}
	return 0;
}
