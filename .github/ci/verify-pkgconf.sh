#!/bin/sh
# devel/pkgconf を当て物入りで入れ替え、落ちないことと、log を立てても
# package が見つかることを見る。
#
# 見るのは三つ。どれも素の pkgconf が OpenBSD で外すもので、他の OS では
# 元から通る (回帰が無いことの確認になる)。
#
#   1. PKG_CONFIG_LOG を立てて --atleast-pkgconfig-version  → rc=0
#      configure が最初に撃つ命令。素の OpenBSD では SIGSEGV (rc=139)
#   2. PKG_CONFIG_LOG を立てて既に入っている package を --exists → rc=0
#      素の OpenBSD では探索路が捨てられて NOT-FOUND (rc=1)
#   3. --exists <無い物> の stderr が空       → 握り潰しが効いている
#      /dev/null が開けていない箱では error がそのまま漏れる
#
# 当て物が当たっただけでは踏まない。1 と 2 は素なら必ず外れるので、
# 通ったこと自体が当て物を通った証拠になる。
PKG=${1:-devel/pkgconf}
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin; export PATH
BMAKE=$PREFIX/bin/bmake; [ -x "$BMAKE" ] || BMAKE=make
T=${TMPDIR:-/tmp}
rc=0

# 入っていない箱では replace は使えない (pkg_delete する相手が無い)。
# macOS の job がここで無言の Error code 1 を出して落ちた。install と
# replace を、入っているかで選ぶ。
if $PREFIX/sbin/pkg_info -e 'pkgconf*' > /dev/null 2>&1; then
	target=replace
else
	target=install
fi
echo "  $target する: $TREE/$PKG"
( cd "$TREE/$PKG" && $BMAKE $target ) > "$T/pkgconf-build.log" 2>&1 || {
	echo "!! pkgconf の $target が落ちた"
	# 無言で落ちることが在るので、末尾だけでなく error らしき行も出す
	grep -nE 'Error code|error:|cannot|refus|conflict' "$T/pkgconf-build.log" \
		| tail -8 | sed 's/^/     /'
	tail -20 "$T/pkgconf-build.log" | sed 's/^/     /'
	exit 1; }
PC=$PREFIX/bin/pkg-config
echo "  版: $($PC --version 2>&1)"

# 素の pkgconf が在るうちに撃っておきたいが、入れ替えた後しか撃てない。
# 代わりに「素なら必ず外れる」命令の結果だけを見る。
L=$T/pkgconf-audit.log

rm -f "$L"
env PKG_CONFIG_LOG="$L" "$PC" --atleast-pkgconfig-version 0.9.0 > /dev/null 2>&1
r=$?
if [ $r -eq 0 ]; then
	echo "  ok log を立てて --atleast-pkgconfig-version が通る"
else
	echo "!! log を立てると --atleast-pkgconfig-version が rc=$r (139 は SIGSEGV)"; rc=1
fi

# 既に入っている .pc を一つ選ぶ。無ければこの検査は飛ばす。
M=$(ls "$PREFIX"/lib/pkgconfig/*.pc 2>/dev/null | head -1)
if [ -n "$M" ]; then
	M=$(basename "$M" .pc)
	rm -f "$L"
	env PKG_CONFIG_LOG="$L" "$PC" --exists "$M" > /dev/null 2>&1
	r=$?
	if [ $r -eq 0 ]; then
		echo "  ok log を立てても $M が見つかる (log: $(tr -d '\n' < "$L"))"
	else
		echo "!! log を立てると $M が見つからない rc=$r (log: $(tr -d '\n' < "$L"))"; rc=1
	fi
else
	echo "  ($PREFIX/lib/pkgconfig に .pc が無いので探索の検査は飛ばす)"
fi

rm -f "$L"
env PKG_CONFIG_LOG="$L" "$PC" --exists nosuchpkg-does-not-exist > /dev/null 2> "$T/pkgconf-err.txt"
n=$(wc -c < "$T/pkgconf-err.txt" | tr -d ' ')
if [ "$n" = 0 ]; then
	echo "  ok error の握り潰しが効いている (stderr 0 byte)"
else
	echo "!! error が漏れている (stderr $n byte) = /dev/null が開けていない"; rc=1
fi

[ $rc -eq 0 ] && echo "  pkgconf: 通った"
exit $rc
