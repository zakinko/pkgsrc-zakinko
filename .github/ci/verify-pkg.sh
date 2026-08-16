#!/bin/sh
# 専用の検査を持たないパッケージ向けの、最低限の確かめ。
#
#   sh verify-pkg.sh <パッケージ名>
#
# mule には verify-mule.sh がある。日本語が編集できるところまで踏まないと
# 「通った」と言えない相手だからで、自作の三つはそこまで要らない。組めて、
# 入って、PLIST どおりのものが置かれて、外せる。そこまで見る。
#
# 自作パッケージの distinfo は追跡していない (README の方針)。無ければ
# その場で makesum する。第三者から引き取った mule だけは distinfo を
# 持っているので、この道は通らない。

PKG=$1
[ -n "$PKG" ] || { echo "usage: $0 <パッケージ名>"; exit 1; }

PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/pkg/bin:/usr/pkg/sbin
PATH=$PATH:/usr/X11R7/bin:/usr/X11R6/bin:/usr/local/bin
export PATH
unset PKG_PATH

OS=$(uname -s)
DIR=/usr/pkgsrc/zakinko/$PKG

if [ "$OS" = NetBSD ]; then
	PKGMAKE=make
	MKARGS=
else
	# base の make は pkgsrc には使えない。bootstrap が入れた bmake を呼ぶ。
	PKGMAKE=/usr/pkg/bin/bmake
	MKARGS="DEPENDS_TARGET=package-install"
fi

echo "--- $PKG ($OS $(uname -r) / $(uname -m)) ---"
cd "$DIR" || { echo "FAIL: $DIR が無い"; exit 1; }

if [ ! -f distinfo ]; then
	echo "--- distinfo が無いので makesum ---"
	$PKGMAKE $MKARGS makesum || { echo "FAIL: makesum できない"; exit 1; }
fi

# 作り直しのときに古いものが残っていると install が拒まれる。
pkg_delete -f "$PKG" > /dev/null 2>&1 || true

echo "--- build と install ---"
if ! $PKGMAKE $MKARGS install; then
	echo "FAIL: $PKG が入らない"
	exit 1
fi

echo "--- 入ったものを見る ---"
pkg_info -e "$PKG" || { echo "FAIL: pkg_info が $PKG を知らない"; exit 1; }
pkg_info -L "$PKG" | sed -n '1,15p'

# PLIST に並べたものが実際に置かれたか。pkg_add は並んでいない物を入れない
# ので、ここで見るのは「並べたのに無い」ほう。
miss=0
for f in $(pkg_info -qL "$PKG" 2>/dev/null); do
	[ -e "$f" ] || { echo "    無い: $f"; miss=$((miss + 1)); }
done
[ $miss -eq 0 ] || { echo "FAIL: $miss 個が置かれていない"; exit 1; }

echo "--- 外せるか ---"
$PKGMAKE deinstall > /dev/null 2>&1 || pkg_delete "$PKG" > /dev/null 2>&1 || {
	echo "FAIL: $PKG が外せない"; exit 1; }

echo "=== 通った: $PKG on $OS ==="
