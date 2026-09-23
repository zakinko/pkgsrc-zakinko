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
grep -q 'OS_VARIANT:U} != "Solaris"' "$M" || {
	echo "!! rust-bin: OS_VARIANT の分岐が入っていない" >&2; exit 1; }
grep -q 'x86_64-unknown-illumos' "$TREE/lang/rust-bin/distinfo" || {
	echo "!! rust-bin: distinfo に illumos が入っていない" >&2; exit 1; }
# rpath の塊は当たっても踏まれたとは限らないので、少なくとも当たったことは
# 数える。踏んだかどうかは verify-rust-bin.sh が SunOS で RUST_RPATH を
# 印字して見る。
grep -q 'RUST_RPATH' "$M" || {
	echo "!! rust-bin: RUST_RPATH の塊が入っていない" >&2; exit 1; }
test "$(grep -c 'set-rpath ${PREFIX}/lib' "$M")" = 0 || {
	echo '!! rust-bin: ${PREFIX}/lib を直に書く set-rpath が残っている' >&2; exit 1; }
echo "  rust-bin: illumos の配布物を上流から取るようにした"
