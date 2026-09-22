#!/bin/sh
# devel/ncurses の当て物だけを当てる。tree-patch-openbsd-all.sh は go-bin と
# openssl も一緒に当てるので、ncurses の効き目だけを測りたいここでは使わない。
# 当てるのは送る diff そのもの。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)
M=$TREE/devel/ncurses/Makefile
if grep -q 'cf_cv_ld_searchpath' "$M"; then
	echo "  ncurses: 上流に追いついている。何もしない"
	exit 0
fi
patch -f -p0 -d "$TREE" < "$D/tree-ncurses-openbsd.diff" > /dev/null
grep -q 'cf_cv_ld_searchpath=/usr/lib' "$M" || {
	echo "!! ncurses: 当て物が入っていない" >&2; exit 1; }
echo "  ncurses: cf_cv_ld_searchpath=/usr/lib を足した ($(sed -n '1s/.*Makefile,v \([0-9.]*\).*/rev \1/p' "$M"))"
