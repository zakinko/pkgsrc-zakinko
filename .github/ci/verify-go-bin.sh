#!/bin/sh
# lang/go-bin が、この OS 向けの公式 binary を選んで入るか。
#
#   sh verify-go-bin.sh lang/go-bin
#
# 三つ見る。
#   1. make distinfo を回しても distinfo が変わらない (手で足した行が、
#      道具が作る物と一字一句同じか。全 platform の tarball を落とすので
#      1GB ほど引く)
#   2. install が通り、go-bin/bin/go version がこの OS と arch を言う
#   3. make show-var VARNAME=DISTFILES がこの OS の tarball 一つだけを指す
PKG=${1:-lang/go-bin}
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin; export PATH
T=${TMPDIR:-/tmp}
BMAKE=$PREFIX/bin/bmake
[ -x "$BMAKE" ] || BMAKE=make
cd "$TREE/$PKG" || { echo "FAIL: $TREE/$PKG が無い"; exit 1; }
rc=0
OS=$(uname -s); ARCH=$(uname -m)
echo "--- $PKG ($OS $(uname -r) / $ARCH) ---"

echo "########## 1. make distinfo で変わらないか ##########"
cp distinfo "$T/distinfo.before"
if $BMAKE distinfo > "$T/go-bin-distinfo.log" 2>&1; then
	if diff -u "$T/distinfo.before" distinfo > "$T/distinfo.diff"; then
		echo "  ok distinfo は make distinfo と同じ"
	else
		echo "!! make distinfo が distinfo を変えた:"; cat "$T/distinfo.diff"; rc=1
		cp "$T/distinfo.before" distinfo
	fi
else
	echo "!! make distinfo が落ちた"; tail -15 "$T/go-bin-distinfo.log"; rc=1
fi

echo "########## 2. install と go version ##########"
_df=$($BMAKE show-var VARNAME=DISTFILES)
echo "  DISTFILES: $_df"
case "$_df" in
*" "*) echo "!! tarball が二つ以上"; rc=1 ;;
esac
if $BMAKE install > "$T/go-bin-install.log" 2>&1; then
	echo "  ok install"
else
	echo "!! install が落ちた"; tail -20 "$T/go-bin-install.log"; rc=1
fi
if [ -x "$PREFIX/go-bin/bin/go" ]; then
	_v=$("$PREFIX/go-bin/bin/go" version 2>&1)
	echo "  $_v"
	_os=$(echo "$OS" | tr 'A-Z' 'a-z')
	case "$_v" in
	"go version go1.24.11 $_os/"*) echo "  ok $_os の binary が動く" ;;
	*) echo "!! version の出力が違う"; rc=1 ;;
	esac
else
	echo "!! go-bin/bin/go が無い"; rc=1
fi

[ $rc -eq 0 ] && echo "RESULT: go-bin はこの OS の binary を選んで入り、動く" || echo "RESULT: 通らなかったものがある (上を読む)"
exit $rc
