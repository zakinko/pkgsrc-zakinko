#!/bin/sh
# lang/rust-bin が SunOS-*-x86_64 の対応を謳っているのに、配布物を指す塊が
# コメントアウトされたままで取りに行く先が無い。上流の rust-lang.org は
# illumos の binary を今も出しているので、そこから取るようにする。
# Solaris は illumos ではないので OS_VARIANT で分ける。送る diff そのもの。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)
M=$TREE/lang/rust-bin/Makefile
if grep -q 'x86_64-unknown-illumos' "$M" && ! grep -q '#RUST_ARCH:=	x86_64-unknown-illumos' "$M"; then
	echo "  rust-bin: 上流に追いついている。何もしない"
	exit 0
fi
patch -f -p0 -d "$TREE" < "$D/tree-rust-bin-illumos.diff" > /dev/null
# illumos と Solaris の両方を、OS_VARIANT で分けて入れる。片方だけ当たって
# いる状態で通すと、片方の箱だけが黙って壊れる。
grep -q 'OS_VARIANT:U} != "Solaris"' "$M" || {
	echo "!! rust-bin: illumos 側の分岐が入っていない" >&2; exit 1; }
grep -q 'OS_VARIANT:U} == "Solaris"' "$M" || {
	echo "!! rust-bin: Solaris 側の分岐が入っていない" >&2; exit 1; }
for _t in x86_64-unknown-illumos x86_64-pc-solaris; do
	grep -q "$_t" "$M" || {
		echo "!! rust-bin: Makefile に $_t が無い" >&2; exit 1; }
	test "$(grep -c "$_t" "$TREE/lang/rust-bin/distinfo")" = 3 || {
		echo "!! rust-bin: distinfo の $_t が 3 行でない" >&2; exit 1; }
done
# ONLY_FOR_PLATFORM は条件で囲まない。両方に上流の binary が在るので、
# 囲むと片方を取りこぼす。囲みが残っていたら古い版が当たっている。
grep -q '^\.if.*OS_VARIANT.*$' "$M" && grep -B2 'ONLY_FOR_PLATFORM+=	SunOS' "$M" |
	grep -q '^\.if' && {
		echo "!! rust-bin: ONLY_FOR_PLATFORM が条件で囲まれている (古い版)" >&2
		exit 1; }
# distinfo は LC_ALL=C sort 順に並ぶ。入れた行で崩れていないか数える。
_o=$(awk '$1=="SHA512"{n=$2; gsub(/[()]/,"",n); print n}' "$TREE/lang/rust-bin/distinfo")
printf '%s\n' "$_o" | LC_ALL=C sort > "$TREE/.distinfo-sorted"
printf '%s\n' "$_o" > "$TREE/.distinfo-asis"
if ! cmp -s "$TREE/.distinfo-asis" "$TREE/.distinfo-sorted"; then
	echo "!! rust-bin: distinfo の並びが sort 順でない" >&2
	diff "$TREE/.distinfo-asis" "$TREE/.distinfo-sorted" | head -6 >&2
	rm -f "$TREE/.distinfo-asis" "$TREE/.distinfo-sorted"
	exit 1
fi
rm -f "$TREE/.distinfo-asis" "$TREE/.distinfo-sorted"
# rpath は触らない。触る版を一度作って OpenIndiana で測ったら、症状が
# 「libgcc_s が見つからない」から「binary が実行できない」に**悪化**した
# (ldd が signal 9 で死ぬ)。rpath は正しく書けていたので、壊しているのは
# 書いた中身ではなく書く行為の側 — patchelf は Linux の道具で、Solaris の
# ELF を編集している。原因を確定するまで混ぜない。切り分けは
# probe-solaris-rpath.sh が測る。
grep -q 'RUST_RPATH' "$M" && {
	echo "!! rust-bin: rpath の塊が混ざっている。切り離したはず" >&2; exit 1; }
# OS_VARIANT を条件に使うので、bsd.prefs.mk より後に在ることを数える。
# 前に置くと bmake が Malformed conditional で止まり、:U を付けると常に偽に
# なって片方の箱が黙って壊れる。
sh "$D/check-mk-vars-after-prefs.sh" "$M" || exit 1
echo "  rust-bin: illumos と Solaris の配布物を上流から取るようにした"
