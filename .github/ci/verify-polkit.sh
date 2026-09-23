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
# で落ちる。NetBSD には ENODATA が在るので落ちない。
#
# 上流は 127 の後に二つの commit で両方とも直している。
#
#	066b55bf2e2b  socket activation の区画を #ifdef SO_PEERPIDFD で囲み、
#	              SO_PEERPIDFD の自前 define を __linux__ だけにする
#	72c28782b17e  SO_PEERCRED を持たない系で建つようにする
#
# 木の当て物は後者と hunk ごと同一で、欠けているのは前者だけである。
# tree-patches/ に在るのは、その二つを素の 127 に patch(1) で当てて diff を
# 取り直したもの。手で hunk を混ぜてはいない。
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

# 落ちた log から、最初の error とその周りを出す。tail だけだと一番下に
# 見えるのは bmake が積み上げた "stopped making" の列で、本当の理由は
# その何十行も上に在る。実際 DragonFly と OpenBSD の run (35848725177) は
# どちらも tail -25 が停止の列で埋まり、原因の行が切れていた。
show_fail() {
	_sf_log=$1
	echo "--- 最初の error / fatal ---"
	grep -nE 'error:|fatal error|\*\*\* Error' "$_sf_log" | head -3
	_sf_n=$(grep -nE 'error:|fatal error' "$_sf_log" | head -1 | cut -d: -f1)
	if [ -n "$_sf_n" ]; then
		echo "--- その周り ---"
		awk -v n="$_sf_n" 'NR>=n-20 && NR<=n+10' "$_sf_log"
	fi
	echo "--- どの package で止まったか ---"
	grep 'stopped making' "$_sf_log" | tail -3
}

d=$TREE/$P
[ -d "$d" ] || { echo "★ $P が pkgsrc に無い"; exit 1; }

src=$WS/.github/ci/tree-patches/patch-src_polkitagent_polkitagenthelper-pam.c
dst=$d/patches/patch-src_polkitagent_polkitagenthelper-pam.c
[ -f "$src" ] || { echo "★ 上流 backport の当て物が repo に無い"; exit 1; }
[ -f "$dst" ] || { echo "★ 木に当て物が無い ($dst)"; exit 1; }

echo "=== 何で建てるか"
uname -a
cc --version 2>/dev/null | head -1 || cc -v 2>&1 | head -1
echo "  polkit: $("$BMAKE" -C "$d" show-var VARNAME=PKGNAME 2>/dev/null)"

echo
echo "=== 当て物を上流 backport (066b55bf + 72c28782) に差し替える"
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
	echo "★ patch 段で落ちた (polkit の依存を建てている途中)"
	show_fail "$WS/.polkit-patch.log"
	exit 1
}
grep -i 'invalid checksum\|Ignoring patch' "$WS/.polkit-patch.log" && {
	echo "★ 当て物が飛ばされた"; exit 1
}
ws=$("$BMAKE" -C "$d" show-var VARNAME=WRKSRC 2>/dev/null)
f=$ws/src/polkitagent/polkitagenthelper-pam.c
[ -f "$f" ] || { echo "★ WRKSRC に file が無い ($f)"; exit 1; }
# 066b55bf が入れる守りが本当に source に在るか。当て物が在ることと、
# 当たっていることは別である。
if grep -q '#ifdef SO_PEERPIDFD' "$f"; then
	echo "  source に #ifdef SO_PEERPIDFD が在る (066b55bf が当たっている)"
else
	echo "★ source に守りが無い。当て物は素通りしている"
	exit 1
fi

echo
echo "=== 建てて入れる"
if "$BMAKE" -C "$d" install > "$WS/.polkit-build.log" 2>&1; then
	echo "  建って入った"
else
	echo "★ 建たない"
	show_fail "$WS/.polkit-build.log"
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
