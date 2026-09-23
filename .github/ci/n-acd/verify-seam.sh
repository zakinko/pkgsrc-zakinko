#!/bin/sh
# n-acd の移植の継ぎ目を、当て物から取り出してその場で建てて測る。
#
# NetworkManager 本体は BSD では継ぎ目より手前で止まるので、本体の build を
# 待っていると継ぎ目は一生測られない。測る対象は package が配る当て物その
# もの — patch の中の + を剥いで file に戻す — なので、当て物を直せばここが
# 測る物も一緒に変わる。写しを置くと、本物を直した日に緑のまま意味を失う。
#
# 建つことと動くことは別なので、建てるだけで終わらせない。timer は実際に
# 焼かせて時刻を測り、framing は kernel が返すのと同じ形の buffer を作って
# 一 byte まで突き合わせる。/dev/bpf を開く所は root が要るのでここでは
# 測らない (NetBSD 実機で別に測ってある)。
set -e

P=NetworkManager/patches
W=${W:-./nacdseam}
rm -rf "$W"; mkdir -p "$W"

# 当て物から中身を取り出す。@@ の次の行から、行頭の + を一つ剥ぐ。
unpatch() {
	awk '/^@@ /{go=1; next} go{sub(/^\+/,""); print}' "$1" > "$2"
	if [ ! -s "$2" ]; then
		echo "★ $1 から中身が取り出せない"
		exit 1
	fi
}

unpatch "$P/patch-src_n-acd_src_n-acd-os.h"     "$W/n-acd-os.h"
unpatch "$P/patch-src_n-acd_src_n-acd-os-bsd.c" "$W/n-acd-os-bsd.c"
cp .github/ci/n-acd/t-timer.c .github/ci/n-acd/t-framing.c "$W/"

echo "=== 何で建てるか"
uname -a
cc --version 2>/dev/null | head -1 || cc -v 2>&1 | head -1

CFLAGS="-std=c11 -Wall -Wextra -I$W"

echo
echo "=== 継ぎ目を建てる (警告が一つでも出たら落とす)"
cd "$W"
if ! cc $CFLAGS -c n-acd-os-bsd.c -o seam.o 2> cc.log; then
	echo "★ 建たない"
	cat cc.log
	exit 1
fi
if [ -s cc.log ]; then
	echo "★ 警告が出た。NetBSD では零だったので、この OS で何かが違う"
	cat cc.log
	exit 1
fi
echo "  建った。警告なし"

echo
echo "=== 継ぎ目が出す名前"
nm -g seam.o 2>/dev/null | grep ' T n_acd_os' | awk '{print "  " $3}' || \
	nm seam.o | grep 'n_acd_os' | awk '{print "  " $3}'

echo
echo "=== timer を測る (焼ける時刻を実際に見る)"
cc $CFLAGS -o t-timer t-timer.c seam.o
./t-timer

echo
echo "=== framing を測る (本物を取り込んだ test)"
cc $CFLAGS -o t-framing t-framing.c
./t-framing

echo
echo "=== 全部通った"
