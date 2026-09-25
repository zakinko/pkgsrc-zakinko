#!/bin/sh
# lang/rust-bin と lang/rust に当てる一本。送る diff そのもの。
#
# 五つのことを一度にやる。別々に当てていたら、まとめたときに古くなる記述に
# 気付かなかった -- Solaris を RUST_BIN_PLATFORMS から外す塊が、rust-bin を
# x86_64-pc-solaris を使う形に変えた時点で嘘になっていた。
#
#	platform.mk (新規)  表 + PLATFORM_SUPPORTS_RUST_BIN
#	ONLY_FOR_PLATFORM   表から .for で組む
#	illumos と Solaris  上流の archive を使う。OS_VARIANT で分ける
#	NetBSD/riscv64      devel/libatomic を引く
#	Darwin              深い install name の書き換えをやめる
#	lang/rust/rust.mk   RUST_TYPE=bin を表に照らす
#
# lang/rust/platform.mk は触らない。あちらは「rust を source から建てられるか」
# の file で、「rust-bin の binary が在るか」は rust-bin の持ち物。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)
M=$TREE/lang/rust-bin/Makefile
P=$TREE/lang/rust-bin/platform.mk

if [ -f "$P" ] && grep -q 'PLATFORM_SUPPORTS_RUST_BIN' "$P"; then
	echo "  rust-bin: 上流に追いついている。何もしない"
	exit 0
fi

# 当てる前の写しを検査の対照にする。上流の無改造が落ちるなら検査が間違い。
_pre=$(mktemp "${TMPDIR:-/tmp}/rust-bin-mk.XXXXXX")
cp "$M" "$_pre"
if ! sh "$D/check-mk-structure.sh" "$_pre" > /dev/null 2>&1; then
	echo "!! 検査が上流の無改造の Makefile を落とす。検査のほうが間違い" >&2
	sh "$D/check-mk-structure.sh" "$_pre" 2>&1 | sed 's/^/   /' >&2
	rm -f "$_pre"; exit 1
fi
rm -f "$_pre"

cp "$D/tree-rust-bin-platform.mk" "$P"
patch -f -p0 -d "$TREE" -i "$D/tree-rust-bin.diff" > /dev/null

# 当たった印。一つでも欠けたら、その platform が黙って落ちる。
for pair in \
	"x86_64-unknown-illumos:illumos の配布物" \
	"x86_64-pc-solaris:Solaris の配布物" \
	'MNetBSD-\*-riscv64:riscv64 の libatomic' \
	"RUST_BIN_PLATFORMS:表から組む形" ; do
	_pat=${pair%%:*}; _name=${pair#*:}
	grep -q "$_pat" "$M" || { echo "!! rust-bin: $_name が入っていない" >&2; exit 1; }
done
# -E を付けない。Solaris 11.4 の /usr/bin/grep には -E が無く、illegal option
# で落ちた exit 1 を「当たらなかった」と読んで、この行が偽の失敗を出していた。
# この pattern は BRE でも ERE でも同じものに当たる (\. 以外に metachar が
# 無い) ので、-E は要らなかった。
grep -q '^\.  for lib in lib$' "$M" || {
	echo "!! rust-bin: Darwin の深い -id が残っている" >&2; exit 1; }
grep -q 'PLATFORM_SUPPORTS_RUST_BIN' "$TREE/lang/rust/rust.mk" || {
	echo "!! rust.mk が表を見ていない" >&2; exit 1; }
# 非 Darwin の patchelf の .for は残っていなければならない。両方消すと
# Linux が黙って壊れる。
grep -q 'for lib in lib lib/rustlib/${RUST_ARCH}/lib' "$M" || {
	echo "!! rust-bin: 非 Darwin 側の .for まで消えている" >&2; exit 1; }
# Solaris を外す古い塊が混ざっていないか。まとめた時点で嘘になった物。
grep -q 'NSunOS' "$P" "$M" && {
	echo "!! rust-bin: Solaris を外す古い塊が混ざっている" >&2; exit 1; }
# distinfo の並びは LC_ALL=C sort 順。
# <(...) は bash だけの形で、sh も dash も syntax error にする。一時 file で。
_a=$(mktemp "${TMPDIR:-/tmp}/di-asis.XXXXXX")
_b=$(mktemp "${TMPDIR:-/tmp}/di-sort.XXXXXX")
awk '$1=="SHA512"{n=$2; gsub(/[()]/,"",n); print n}' "$TREE/lang/rust-bin/distinfo" > "$_a"
LC_ALL=C sort "$_a" > "$_b"
if ! cmp -s "$_a" "$_b"; then
	echo "!! rust-bin: distinfo の並びが sort 順でない" >&2
	diff "$_a" "$_b" | head -6 >&2
	rm -f "$_a" "$_b"; exit 1
fi
rm -f "$_a" "$_b"
sh "$D/check-mk-structure.sh" "$M" || exit 1
sh "$D/check-mk-structure.sh" "$P" || exit 1
echo "  rust-bin: 表に畳み、illumos/Solaris/riscv64/Darwin と rust.mk を入れた"
