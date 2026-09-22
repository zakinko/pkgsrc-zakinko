#!/bin/sh
# pkgtools/libnbcompat の lchflags.c が chflags(2) の有無を OS の名前で
# 決めていて、Solaris がその列に無いので bootstrap が落ちる。configure に
# chflags を訊かせて HAVE_CHFLAGS で分ける。送る diff そのものを当てる。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)
F=$TREE/pkgtools/libnbcompat/files/lchflags.c
if grep -q 'HAVE_CHFLAGS' "$F"; then
	echo "  libnbcompat: 上流に追いついている。何もしない"
	exit 0
fi
patch -f -p0 -d "$TREE" < "$D/tree-libnbcompat-chflags.diff" > /dev/null
for c in 'lchflags.c:HAVE_CHFLAGS' 'configure:ac_cv_func_chflags' \
	 'configure.ac:AC_CHECK_FUNCS(\[chflags\])' 'nbcompat/config.h.in:HAVE_CHFLAGS'; do
	f=${c%%:*}; k=${c#*:}
	grep -q "$k" "$TREE/pkgtools/libnbcompat/files/$f" || {
		echo "!! libnbcompat: $f に $k が入っていない" >&2; exit 1; }
done
echo "  libnbcompat: lchflags の chflags 判定を HAVE_CHFLAGS にした"
