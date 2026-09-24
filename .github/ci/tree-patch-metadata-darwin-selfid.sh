#!/bin/sh
# Darwin で、dylib 自身の install name が package の REQUIRES に入る。
# PR pkg/58966 が記録している問題で、otool -L が各 file の先頭に自分の
# install name を出すのを、REQUIRES を作る awk が依存として数えている。
#
# 今まで表に出なかったのは、install name を全部絶対 path に書き換えていた
# から。下流の filter が PLIST に在る物を落とすので、自分の id も一緒に
# 落ちていた。@rpath のまま残す package が出ると噛み合わなくなる。
#
#	pkg_add: rust-bin-1.96.1: missing required library:
#	@rpath/libstd-c230e80c85060539.dylib
#
# lang/rust-bin の Darwin/x86_64 がそれで、install_name_tool が長い絶対
# path を load command に収められない (71 字まで、必要 74 字。実測)。
#
# 直し方は、file 自身が dylib のときだけ先頭の一件を飛ばす。実行 file は
# LC_ID_DYLIB を持たないので先頭は本当の依存で、そちらは残す。
#
# 送る diff そのもの。mk/ を触るので、rust-bin 側の当て物とは別に出す。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)
M=$TREE/mk/pkgformat/pkg/metadata.mk

[ -f "$M" ] || { echo "  metadata.mk が無い。何もしない"; exit 0; }

if grep -q 'isdylib' "$M"; then
	echo "  metadata.mk: 上流に追いついている。何もしない"
	exit 0
fi

patch -f -p0 -d "$TREE" < "$D/tree-metadata-darwin-selfid.diff" > /dev/null

grep -q 'isdylib = (length(h) > 6' "$M" || {
	echo "!! metadata.mk: 当て物が入っていない" >&2; exit 1; }
# 埋め込んだ awk を取り出して、実際に走ることを確かめる。make の $$ を $ に
# 戻す。埋める形が壊れていても grep は当たるので、走らせるところまで見る。
_a=$(mktemp "${TMPDIR:-/tmp}/selfid.XXXXXX")
sed -n 's/.*\${AWK} .\(\/\^\[\^.*\). | \${SORT} -u.*/\1/p' "$M" | sed 's/\$\$/$/g' > "$_a"
if [ ! -s "$_a" ]; then
	echo "!! metadata.mk: 埋め込んだ awk を取り出せない" >&2; rm -f "$_a"; exit 1
fi
# 既知の入力で、self-id が落ち本当の依存が残ることを見る。
_in=$(mktemp "${TMPDIR:-/tmp}/selfid-in.XXXXXX")
printf 'x/libfoo.dylib:\n\t@rpath/libfoo.dylib (compatibility version 0.0.0)\n\t/usr/lib/libSystem.B.dylib (compatibility version 1.0.0)\nx/bin/prog:\n\t@rpath/libbar.dylib (compatibility version 0.0.0)\n' > "$_in"
_got=$(awk -f "$_a" "$_in" | sort | tr '\n' ' ')
rm -f "$_a" "$_in"
_want="/usr/lib/libSystem.B.dylib @rpath/libbar.dylib "
if [ "$_got" != "$_want" ]; then
	echo "!! metadata.mk: 埋め込んだ awk が期待どおり動かない" >&2
	echo "   得た:   $_got" >&2
	echo "   期待:   $_want" >&2
	exit 1
fi
echo "  metadata.mk: dylib 自身の install name を REQUIRES から外した"
