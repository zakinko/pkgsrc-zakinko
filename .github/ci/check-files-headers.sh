#!/bin/sh
# */files/*.h が C として読めるかを見る。
#
#   sh .github/ci/check-files-headers.sh [パッケージ ...]
#
# なぜ要るか
# ----------
# mule2/files/openbsd.h の 35 行目に、shell の command が一行入っていた。
#
#     /* Every OpenBSD that pkgsrc still builds for is ELF.  netbsd.h already
#        picks unexelf.o under __ELF__; this is here to say so out loud.  */
#     tail -6 $C/mule2/files/openbsd.h | cut -c1-70
#
# file を作った 2026-09-01 の commit から入っていた。困るのは、この file が
# OpenBSD でしか読まれないこと。NetBSD でも Linux でも FreeBSD でも compile
# されないので、build は緑のまま通る。
#
# 出てきたのは OpenBSD の CI で、しかも C の error としてではなかった。
# s/openbsd.h は src/config.h から読まれ、その config.h は Makefile.in.in を
# cpp に通して Makefile を作るのにも使われる。混ざった行はそのまま Makefile
# へ流れ、
#
#     Makefile:109: *** missing separator.  Stop.
#
# になる。lib-src の compile より前なので C の診断は一つも出ない。原因に
# 辿り着くまでに、VM を起こす run を四度使った。
#
# 見かたは cc -fsyntax-only。註と指令だけを許す形の検査も書いてみたが、
# emacs21/files/darwin.h の "struct kboard;" のような正しい宣言まで叩いて
# しまい、使いものにならなかった。読めるかどうかは compiler に訊く。
#
# これらの file は木の中の別の header を #include "..." で引く。ここには
# 無いので、名前だけの空 file を作って通す。中身は見ない。見たいのは、
# この file 自身に C でない行が混ざっていないかどうか。

PKGSRCDIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$PKGSRCDIR" || exit 1

CC=${CC:-cc}
command -v "$CC" > /dev/null 2>&1 || { echo "SKIP: $CC が無い"; exit 0; }

if [ $# -gt 0 ]; then
	dirs=$*
else
	dirs=$(ls -d */files 2>/dev/null | sed 's|/files$||')
fi

tmp=${TMPDIR:-/tmp}/cfh.$$
rc=0
n=0
for pkg in $dirs; do
	for f in "$pkg"/files/*.h; do
		[ -f "$f" ] || continue
		n=$((n + 1))
		rm -rf "$tmp"; mkdir -p "$tmp" || exit 1
		# 引いている木の中の header を、名前だけの空 file で置く。
		sed -n 's/^[ 	]*#[ 	]*include[ 	]*"\([^"]*\)".*/\1/p' "$f" |
		while read -r inc; do
			mkdir -p "$tmp/$(dirname "$inc")" 2>/dev/null
			: > "$tmp/$inc"
		done
		out=$($CC -fsyntax-only -w -x c -I"$tmp" "$f" 2>&1)
		if [ -n "$out" ]; then
			echo "NG: $f が C として読めない"
			echo "$out" | sed 's/^/  /'
			rc=1
		fi
	done
done
rm -rf "$tmp"

if [ $rc -eq 0 ]; then
	echo "OK: files/*.h $n 本、C として読める"
fi
exit $rc
