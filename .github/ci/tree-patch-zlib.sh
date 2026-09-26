#!/bin/sh
# devel/zlib を 1.3.2 へ上げる。送る diff と同じ物。
#
# 1.3.1 の crc32_combine64 と crc32_combine_gen64 は長さをそのまま x2nmodp に
# 渡す。x2nmodp の loop は n >>= 1 で回るので、負の値だと算術 shift で -1 の
# まま止まらない (CVE-2026-27171)。上流は 1.3.2 で len2 < 0 なら 0 を返す
# 番人を入れた。
#
# 当て物で番人だけを足すこともできるが、doc/TODO が zlib-1.3.2 を求めており、
# 版を上げれば番人は上流の物として入り、pkg-vulnerabilities の既定の
# zlib<1.3.2 もそのまま正しくなる。pkgsrc の devel/zlib は distfile を取らず
# source を files/ に持つので、上げるとは files/ を 1.3.2 の物に入れ替える
# ことである。
#
# 木が 1.3.1 に足していた物は二つだけで、どちらも持ち越してある。
#
#	files/Makefile   pkgsrc 自前の差し替え。1.3.2 でも手を付けない
#	files/gzguts.h   #include <unistd.h> の一行。1.3.2 にも無い
#
# 他の 26 file の差は CVS の $Id$ 展開だけなので、その行は木の物を残した。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)
if grep -q 'ZLIB_VERSION "1.3.2"' "$TREE/devel/zlib/files/zlib.h"; then
	echo "  zlib: 既に 1.3.2。何もしない"
	exit 0
fi
patch -f -p0 -d "$TREE" < "$D/tree-zlib-132.diff" > /dev/null
for c in 'ZLIB_VERSION "1.3.2":files/zlib.h' 'len2 < 0:files/crc32.c' \
         'include <unistd.h>:files/gzguts.h'; do
	pat=${c%:*}; f=${c#*:}
	grep -q "$pat" "$TREE/devel/zlib/$f" || { echo "!! zlib: $f に $pat が無い" >&2; exit 1; }
done
grep -q 'DISTNAME=	zlib-1.3.2' "$TREE/devel/zlib/Makefile" \
	|| { echo "!! zlib: DISTNAME が上がっていない" >&2; exit 1; }
echo "  zlib: 1.3.2 へ上げた (負の長さの番人は上流の物として入る)"
