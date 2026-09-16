#!/bin/sh
# devel/gdb7 が Darwin/aarch64 で建たない件 (GitHub NetBSD/pkgsrc #187) を、
# 再現してから、PR の一行が効くこと、そして「直す」道が無いことを見せる。
#
#   sh verify-gdb7.sh <カテゴリ>/<パッケージ>
#
# PR #187 は devel/gdb (10.1) が 2023-07 に triaxx@ で得た行を gdb7 にも写す。
#
#	NOT_FOR_PLATFORM+=	Darwin-*-aarch64
#
# 作者の報告は、同梱 zlib の zutil.h:128 が fdopen を NULL に define して
# macOS SDK の _stdio.h の宣言と衝突する、というもの。作者は続けて
# --with-system-zlib で「compile は通るが PLIST で落ちる」と書いている。
#
# 三段で見る。
#
#   1. 素の gdb7 を建てる。zutil.h の衝突で止まるのが再現か。
#   2. PR の一行を入れる。pkgsrc が Darwin-*-aarch64 を拒むか。
#   3. 作者の言う system zlib へ振る。zlib を越えた先に gdb が在るか。
#      無い。gdb 7.11 の toplevel configure.ac:1026 が
#
#	aarch64-*-darwin*)
#	  noconfigdirs="$noconfigdirs ld gas gdb gprof"
#
#      と gdb の directory そのものを外すので、make build は通り、install が
#      PLIST の bin/gdb、include/gdb/jit-reader.h、info、man を「無い」と
#      並べる。作者の「compile は通るが PLIST で落ちる」はこれである。
#      gdb/configure.host も native の片を config/i386/darwin.mh しか持たない。
#      つまり「建たない」(BROKEN_ON_PLATFORM) ではなく「支えていない」
#      (NOT_FOR_PLATFORM) で、PR の選択が正しい。
#
# python option は切って走らせる。報告された段は zlib で、python27 は関係が
# 無いうえ、この箱で建てるのに時間が掛かる。

PKG=${1:-devel/gdb7}
case $PKG in */*) : ;; *) PKG=devel/gdb7 ;; esac

OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
export PATH
if [ -x "$PREFIX/bin/bmake" ]; then PKGMAKE=$PREFIX/bin/bmake
else PKGMAKE=make; fi
OPT="PKG_OPTIONS.gdb=-python"
T=${TMPDIR:-/tmp}

cd "$TREE/$PKG" || { echo "FAIL: $TREE/$PKG が無い"; exit 1; }
rc=0
echo "--- $PKG ($OS $(uname -r) / $(uname -m)) ---"
echo "MACHINE_PLATFORM = $($PKGMAKE show-var VARNAME=MACHINE_PLATFORM)"
cp Makefile "$T/gdb7-Makefile.orig"
restore() { cp "$T/gdb7-Makefile.orig" Makefile; }

build() {
	_tag=$1
	$PKGMAKE clean > /dev/null 2>&1
	{ $PKGMAKE $OPT build 2>&1; echo $? > "$T/gdb7-rc"; } > "$T/gdb7-$_tag.log" 2>&1
	return "$(cat "$T/gdb7-rc")"
}

echo
echo "########## 1. 素のまま ##########"
if build plain; then
	echo "!! 建った。#187 の前提がこの箱では再現しない"
	rc=1
else
	if grep -q 'zutil.h.*fdopen\|expanded from macro .fdopen' "$T/gdb7-plain.log"; then
		echo "  ok 再現: 同梱 zlib の fdopen が SDK の宣言と衝突して止まる"
		grep -n 'error: expected identifier\|zutil.h:.*fdopen' "$T/gdb7-plain.log" | head -3
	else
		echo "!! 落ちたが、報告と違う所で落ちている"
		grep -n 'error:' "$T/gdb7-plain.log" | head -5
		tail -15 "$T/gdb7-plain.log"
		rc=1
	fi
fi

echo
echo "########## 2. PR #187 の一行を入れる ##########"
awk '/^LICENSE=/ { print; print ""; print "NOT_FOR_PLATFORM+=\tDarwin-*-aarch64"; next } { print }' \
	Makefile > Makefile.new && mv Makefile.new Makefile
grep -n 'NOT_FOR_PLATFORM' Makefile
$PKGMAKE clean > /dev/null 2>&1
if $PKGMAKE $OPT build > "$T/gdb7-pr.log" 2>&1; then
	echo "!! 拒まれずに建った"; rc=1
elif grep -q 'not available for these platforms' "$T/gdb7-pr.log"; then
	echo "  ok pkgsrc が拒む:"
	grep -n 'not available for these platforms' "$T/gdb7-pr.log" | head -1
else
	echo "!! 落ちたが NOT_FOR_PLATFORM の文言ではない"
	tail -10 "$T/gdb7-pr.log"; rc=1
fi
restore

echo
echo "########## 3. 作者の言う system zlib へ振る ##########"
awk '/^\.include "\.\.\/\.\.\/mk\/termcap\.buildlink3\.mk"$/ {
	print ".include \"../../devel/zlib/buildlink3.mk\""
	print "CONFIGURE_ARGS+=\t--with-system-zlib"
} { print }' Makefile > Makefile.new && mv Makefile.new Makefile
grep -n 'zlib' Makefile
if build syszlib; then
	echo "  zlib は越えた。gdb が組まれたかを見る"
	_wrksrc=$($PKGMAKE show-var VARNAME=WRKSRC)
	if [ -x "$_wrksrc/gdb/gdb" ]; then
		echo "!! gdb の実行 file が出来ている。ならば直せる可能性が在る"; rc=1
	elif grep -q 'Configuring in .*/gdb$\|Configuring in ./gdb' "$T/gdb7-syszlib.log"; then
		echo "!! gdb の directory が configure されている"; rc=1
	else
		echo "  ok gdb の directory は configure されていない (toplevel が noconfigdirs に入れる)"
		grep -n 'Configuring in' "$T/gdb7-syszlib.log" | sed 's/^/     /' | head -12
		$PKGMAKE $OPT install > "$T/gdb7-syszlib-install.log" 2>&1 && { echo "!! install が通った"; rc=1; } || {
			if grep -q 'PLIST but not in.*' "$T/gdb7-syszlib-install.log" &&
			   grep -q '/bin/gdb$' "$T/gdb7-syszlib-install.log"; then
				echo "  ok install は PLIST の bin/gdb を「無い」と並べる (作者の見たもの)"
				grep -n 'ERROR: *.*\(bin/gdb\|jit-reader\|\.info\|\.1\|\.5\)$' "$T/gdb7-syszlib-install.log" | head -8
			else
				echo "?? install が別の理由で落ちた"; grep -n ERROR "$T/gdb7-syszlib-install.log" | head; rc=1
			fi
		}
	fi
elif grep -q 'does not support native target' "$T/gdb7-syszlib.log"; then
	echo "  ok gdb 自身の configure が host を支えていない:"
	grep -n 'does not support native target' "$T/gdb7-syszlib.log" | head -2
elif grep -q 'zutil.h.*fdopen\|expanded from macro .fdopen' "$T/gdb7-syszlib.log"; then
	echo "!! system zlib にしても同梱 zlib が組まれている"
	grep -n 'zutil.h' "$T/gdb7-syszlib.log" | head -3; rc=1
else
	echo "?? zlib は越えたが別の所で落ちた (これは記録する)"
	grep -n 'error:\|Error [0-9]' "$T/gdb7-syszlib.log" | head -10
	tail -20 "$T/gdb7-syszlib.log"
fi
restore
$PKGMAKE clean > /dev/null 2>&1

echo
[ $rc -eq 0 ] && echo "RESULT: #187 の前提は再現し、一行は効き、zlib の先に gdb は無い" \
	|| echo "RESULT: 見込みと違う所が在る (上を読む)"
exit $rc
