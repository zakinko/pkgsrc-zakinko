#!/bin/sh
# security/polkit を各 OS で建てる。
#
#	sh verify-polkit.sh <カテゴリ>/<パッケージ>
#
# build-on-bsd.sh の TREE_PKGS の口から呼ばれる。bootstrap の後なので
# bmake も digest も在る — TREE_PATCH の口は bootstrap の前に走るので、
# そちらでは distinfo を数え直せない。
#
# 何をしているか
# --------------
# 木の patch-src_polkitagent_polkitagenthelper-pam.c は SO_PEERCRED の半分
# しか持たない。polkit-127 の同じ file は SO_PEERPIDFD を持たない系でも
# 自前で 77 と define するので pidfd の区画が常に compile され、その中で
# errno を ENODATA と比べる。ENODATA を持たない FreeBSD 系は
#
#	polkitagenthelper-pam.c:156:48: error: use of undeclared identifier 'ENODATA'
#
# で落ちる。NetBSD には ENODATA が在るので落ちない。FreeBSD ports 側の半分を
# 足した合成版が tree-patches/ に在るので、それに差し替えて建てる。
#
# distinfo は当該の一行だけ数え直す。全体を makepatchsum で書き直すと、
# digest が黙ったときに pkgsrc 本体の distinfo.awk の bug を踏んで
#
#	SHA1 (A) = SHA1 (B) = <B の hash>
#
# と二件が一行に繋がる。行数も行末も合うので検査をすり抜け、pkgsrc は
# invalid checksum として当て物を黙って飛ばし、polkit が素で建つ。

P=${1:?usage: verify-polkit.sh <category>/<pkg>}
# qemu の口 (run-in-qemu.sh) は TREE も PREFIX も渡さない。NetBSD の
# ゲストでの既定を置く。
TREE=${TREE:-/usr/pkgsrc}
PREFIX=${PREFIX:-/usr/pkg}
WS=${WS:-$(cd "$(dirname "$0")/../.." && pwd)}

# bootstrap した系は $PREFIX/bin/bmake、NetBSD は base の make が bmake で
# ある。名前で決め打ちしない。
BMAKE=
for m in "$PREFIX/bin/bmake" bmake make; do
	command -v "$m" > /dev/null 2>&1 && { BMAKE=$m; break; }
done
[ -n "$BMAKE" ] || { echo "★ bmake が無い"; exit 1; }

. "$WS/.github/ci/patch-sha1.sh"

d=$TREE/$P
[ -d "$d" ] || { echo "★ $P が pkgsrc に無い"; exit 1; }

src=$WS/.github/ci/tree-patches/patch-src_polkitagent_polkitagenthelper-pam.c
dst=$d/patches/patch-src_polkitagent_polkitagenthelper-pam.c
[ -f "$src" ] || { echo "★ 合成版が repo に無い"; exit 1; }
[ -f "$dst" ] || { echo "★ 木に当て物が無い ($dst)"; exit 1; }

echo "=== 何で建てるか"
uname -a
cc --version 2>/dev/null | head -1 || cc -v 2>&1 | head -1
echo "  polkit: $("$BMAKE" -C "$d" show-var VARNAME=PKGNAME 2>/dev/null)"

echo
echo "=== 当て物を合成版に差し替える"
if grep -q 'SO_PEERPIDFD' "$dst"; then
	echo "  既に SO_PEERPIDFD を見ている。そのまま"
else
	cp "$dst" "$d/patches/.orig-pam" || exit 1
	cp "$src" "$dst" || exit 1
	h=$(patch_sha1 "$dst") || { cp "$d/patches/.orig-pam" "$dst"; exit 1; }
	n=$(basename "$dst")
	awk -v n="$n" -v h="$h" '
		$0 ~ "^SHA1 \\(" n "\\) = " { print "SHA1 (" n ") = " h; next }
		{ print }
	' "$d/distinfo" > "$d/distinfo.new" && mv "$d/distinfo.new" "$d/distinfo" || exit 1

	# 書けたかは跡で測る。行数だけでは二件が繋がった形を見逃す。
	want=$(ls "$d/patches" | grep -c '^patch-')
	got=$(grep -c '^SHA1 (patch-' "$d/distinfo")
	ent=$(grep -o 'SHA1 (patch-' "$d/distinfo" | wc -l | tr -d ' ')
	bad=$(grep '^SHA1 (patch-' "$d/distinfo" | grep -cv '= [0-9a-f]*$')
	if [ "$want" = "$got" ] && [ "$got" = "$ent" ] && [ "$bad" = 0 ]; then
		echo "  差し替えて一行だけ数え直した (当て物 $want 本)"
		grep 'polkitagenthelper-pam' "$d/distinfo" | sed 's/^/    /'
	else
		echo "★ distinfo が壊れた (当て物 $want / 行 $got / 出現 $ent / 変な行 $bad)"
		exit 1
	fi
fi

echo
echo "=== 当てて、当たった跡を見る"
"$BMAKE" -C "$d" patch > "$WS/.polkit-patch.log" 2>&1 || {
	echo "★ patch 段で落ちた"; tail -25 "$WS/.polkit-patch.log"; exit 1
}
grep -i 'invalid checksum\|Ignoring patch' "$WS/.polkit-patch.log" && {
	echo "★ 当て物が飛ばされた"; exit 1
}
ws=$("$BMAKE" -C "$d" show-var VARNAME=WRKSRC 2>/dev/null)
f=$ws/src/polkitagent/polkitagenthelper-pam.c
[ -f "$f" ] || { echo "★ WRKSRC に file が無い ($f)"; exit 1; }
# 合成版が入れる守りが本当に source に在るか。当て物が在ることと、
# 当たっていることは別である。
if grep -q '#ifdef SO_PEERPIDFD' "$f"; then
	echo "  source に #ifdef SO_PEERPIDFD が在る (合成版が当たっている)"
else
	echo "★ source に守りが無い。当て物は素通りしている"
	exit 1
fi

echo
echo "=== 建てて入れる"
if "$BMAKE" -C "$d" install > "$WS/.polkit-build.log" 2>&1; then
	echo "  建って入った"
else
	echo "★ 建たない。最初の error の周り:"
	grep -n -m1 -iE 'error:|\*\*\* Error' "$WS/.polkit-build.log" |
		while IFS=: read -r ln _; do
			sed -n "$((ln>12?ln-12:1)),$((ln+8))p" "$WS/.polkit-build.log"
		done
	exit 1
fi

echo
echo "=== 入った物を見る"
(pkg_info -e polkit || "$PREFIX/sbin/pkg_info" -e polkit || /usr/sbin/pkg_info -e polkit) 2>/dev/null | sed 's/^/  /' || true
for b in polkit-agent-helper-1 pkexec pkttyagent; do
	p=$(find "$PREFIX" -name "$b" -type f 2>/dev/null | head -1)
	if [ -n "$p" ]; then
		printf '  %-24s %s\n' "$b" "$p"
	else
		echo "★ $b が入っていない"; exit 1
	fi
done
"$PREFIX/bin/pkexec" --version 2>&1 | head -1 | sed 's/^/  /'

echo
echo "=== 通った"
