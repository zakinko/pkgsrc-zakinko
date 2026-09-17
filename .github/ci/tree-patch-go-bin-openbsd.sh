#!/bin/sh
# pkgsrc の go を OpenBSD で bootstrap できるようにする当て物。送る diff と
# 同じ物 (tree-go-bin-openbsd.diff) をそのまま木に当てる。
#
# lang/go/bootstrap.mk は Darwin と FreeBSD 14 と aarch64 と illumos だけ
# go-bin を使い、他は lang/go14 を source から組んで go118 -> ... -> go127
# と登る。OpenBSD 7.9 では go14 の make.bash が
#
#	./make.bash: line 170: 86020 Abort trap (core dumped)
#	    "$GOTOOLDIR"/go_bootstrap clean -i std
#
# で止まる (run 35125854518)。go-bin に openbsd-amd64 の
# 公式 binary を足し、bootstrap.mk の条件に OpenBSD を足す。
#
# 上流に入ったら bootstrap.mk の grep が当たって何もしない。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)/tree-go-bin-openbsd.diff
if grep -q '"OpenBSD"' "$TREE/lang/go/bootstrap.mk"; then
	echo "  go: bootstrap.mk は既に OpenBSD を見ている。何もしない"
	exit 0
fi
# 当てる前の三つを木の外に取っておく。verify-go127.sh が pkglint の
# 出力を当てる前と後で比べるのに使う。package の中に .orig を残すと
# pkglint がそれを咎めるので、外に置く。
for f in lang/go-bin/Makefile lang/go-bin/distinfo lang/go/bootstrap.mk; do
	mkdir -p "$TREE/.ci-orig/$(dirname "$f")"
	cp "$TREE/$f" "$TREE/.ci-orig/$f"
done
patch -f -p0 -d "$TREE" < "$D" > /dev/null
grep -q 'openbsd-amd64' "$TREE/lang/go-bin/distinfo" || { echo "!! go-bin: distinfo に入っていない" >&2; exit 1; }
echo "  go: go-bin に openbsd-amd64 を足し、bootstrap.mk の go-bin の条件に OpenBSD を足した"
