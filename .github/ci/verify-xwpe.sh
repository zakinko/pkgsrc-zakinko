#!/bin/sh
# xwpe の当て物 3 本が今も要ることを、当てる前後を建て分けて見る。
#
#   sh verify-xwpe.sh <カテゴリ>/<パッケージ>
#
# 何を見ているか
# --------------
# GitHub の NetBSD/pkgsrc PR #180 は editors/xwpe を 1.6.6 へ上げるもの。
# 出したのは Debian のメンテナで、かつ xwpe の現上流でもある。今の上流は
# 1.6.9 まで進んでいる。
#
# 1.5.30a 向けの当て物 9 本のうち 6 本は要らなくなった。patch-aa が直して
# いた DESTDIR の壊れ (手書き Makefile.in が DESTDIR を bindir の意味で
# 使っていた) は、1.6.x が autotools へ移ったので消えている。他の 5 本は
# 上流が取り込んだ。
#
# 残す 3 本は、どれもコンパイラの診断である。
#
#   patch-WeXterm.c      e_X_sw_color の暗黙の宣言
#   patch-we__xterm.c    WpeMouseRestoreShape への不正なキャスト
#   patch-we__wayland.c  同上 (1.6.6 で入った Wayland 側)
#
# **Debian は 1.6.6-1 で当て物をゼロにしている** (debian/patches/series が
# 空)。同じ人が上流とメンテナを兼ねているので、要らないから消したように
# 見える。だが Debian は gcc 既定で組む。gcc の既定ではこの二つは警告で、
# clang では error である。
#
#   error: incompatible function pointer types assigning to 'void (*)(void)'
#          from 'void (*)(WpeMouseShape)' [-Wincompatible-function-pointer-types]
#   error: call to undeclared function 'e_X_sw_color';
#          ISO C99 and later do not support implicit function declarations
#
# pkgsrc は clang の箱でも組むので、当て物を落とすと通らなくなる箱がある。
# それをここで示す。示せなければ当て物は要らないので、そのときは落とす。
#
# 見るのは三つ。
#
#   1. 当て物ありで建てる    -> 通るはず
#   2. 建った実体を動かす    -> 起動して終われるか
#   3. 当て物を外して建て直す -> clang の箱では落ちるはず。gcc の箱では
#                               通るかもしれない。どちらだったかを記録する
#
# 3 が箱によって割れるのが、この検査の見どころである。割れ方そのものが
# 「なぜ Debian は要らず pkgsrc は要るのか」の答えになる。

PKG=${1:-zakinko/xwpe}

OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}

PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
PATH=$PATH:/usr/X11R7/bin:/usr/X11R6/bin
export PATH
unset PKG_PATH

if [ -x "$PREFIX/bin/bmake" ]; then
	PKGMAKE=$PREFIX/bin/bmake
	MKARGS="DEPENDS_TARGET=bin-install"
elif [ "$OS" = NetBSD ]; then
	PKGMAKE=make
	MKARGS=
else
	echo "FAIL: $PREFIX/bin/bmake が無い"; exit 1
fi

PKGBASE=${PKG##*/}
DIR=$TREE/$PKG
cd "$DIR" || { echo "FAIL: $DIR が無い"; exit 1; }

rc=0
echo "--- $PKG ($OS $(uname -r) / $(uname -m)) ---"
echo "--- コンパイラ ---"
${CC:-cc} --version 2>/dev/null | head -1

# ------------------------------------------------------------------
echo
echo "########## 1. 当て物ありで建てる ##########"
ls patches 2>/dev/null
pkg_delete -f "$PKGBASE" > /dev/null 2>&1 || true
{ $PKGMAKE $MKARGS install 2>&1; echo $? > /tmp/xwpe-rc; } | tee /tmp/xwpe-patched.log
if [ "$(cat /tmp/xwpe-rc)" -eq 0 ]; then
	echo 'RESULT 当て物あり: 通った'
else
	echo 'RESULT 当て物あり: 落ちた'
	tail -40 /tmp/xwpe-patched.log
	rc=1
fi

# ------------------------------------------------------------------
echo
echo "########## 2. 建った実体を動かす ##########"
# X も端末も無いので編集まではできない。起動して名乗って終われるところ
# までを見る。組めても即座に落ちる、を弾くための最低限。
if [ -x "$PREFIX/bin/we" ]; then
	"$PREFIX/bin/we" -h < /dev/null > /tmp/xwpe-run.log 2>&1
	echo "  we -h の終了状態: $?"
	head -5 /tmp/xwpe-run.log
	for f in "$PREFIX/lib/xwpe/syntax_def" "$PREFIX/lib/xwpe/help.xwpe" \
	         "$PREFIX/share/applications/xwpe.desktop"; do
		[ -e "$f" ] && echo "  ok $f" || { echo "  無い: $f"; rc=1; }
	done
else
	echo "!! $PREFIX/bin/we が無い"
	rc=1
fi

# ------------------------------------------------------------------
echo
echo "########## 3. 当て物を外して建て直す ##########"
# これが箱によって割れる。落ちれば「この箱には要る」、通れば「この箱には
# 要らない」。どちらも結果であって、失敗ではない。
mkdir -p /tmp/xwpe-patches && cp patches/* /tmp/xwpe-patches/ 2>/dev/null
cp distinfo /tmp/xwpe-distinfo.orig
$PKGMAKE clean > /dev/null 2>&1
pkg_delete -f "$PKGBASE" > /dev/null 2>&1 || true
rm -f patches/patch-WeXterm.c patches/patch-we__xterm.c patches/patch-we__wayland.c
sed -e '/patch-WeXterm.c/d' -e '/patch-we__xterm.c/d' -e '/patch-we__wayland.c/d' \
	distinfo > distinfo.new && mv distinfo.new distinfo

{ $PKGMAKE $MKARGS build 2>&1; echo $? > /tmp/xwpe-rc; } | tee /tmp/xwpe-plain.log
if [ "$(cat /tmp/xwpe-rc)" -eq 0 ]; then
	echo "RESULT 当て物なし: 通った ($OS のこの箱では当て物は要らない)"
else
	echo "RESULT 当て物なし: 落ちた ($OS のこの箱では当て物が要る)"
fi
echo '--- 診断に出た行 ---'
grep -nE 'incompatible function pointer|undeclared function|implicit declaration' \
	/tmp/xwpe-plain.log | head -10

# 戻す
cp /tmp/xwpe-patches/* patches/ 2>/dev/null
cp /tmp/xwpe-distinfo.orig distinfo
$PKGMAKE clean > /dev/null 2>&1

[ $rc -eq 0 ] && echo "=== 通った: $PKG on $OS ===" ||
	echo "=== 見込みと違った: $PKG on $OS ==="
exit $rc
