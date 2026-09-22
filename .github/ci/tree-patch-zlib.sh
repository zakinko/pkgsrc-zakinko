#!/bin/sh
# devel/zlib の crc32_combine64 に負の長さの番人を置く。送る diff と同じ物。
#
# zlib 1.3.1 の crc32_combine64 と crc32_combine_gen64 は長さをそのまま
# x2nmodp に渡す。x2nmodp の loop は n >>= 1 で回るので、負の値だと
# 算術 shift で -1 のまま止まらない (CVE-2026-27171)。上流は 1.3.2 で
# len2 < 0 なら 0 を返す番人を入れた (commit ba829a4、2025-12-22
# "Check for negative lengths in crc32_combine functions")。pkgsrc の
# devel/zlib は source を files/ に持っているので、その commit と同じ物を
# crc32.c と zlib.h に置く。NetBSD と FreeBSD の base の zlib は
# どちらも既にこの番人を持っている。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)
if grep -q 'len2 < 0' "$TREE/devel/zlib/files/crc32.c"; then
	echo "  zlib: 既に番人が在る。何もしない"
	exit 0
fi
patch -f -p0 -d "$TREE" < "$D/tree-zlib-crc32.diff" > /dev/null
grep -q 'len2 < 0' "$TREE/devel/zlib/files/crc32.c" || { echo "!! zlib: 当たっていない" >&2; exit 1; }
echo "  zlib: crc32_combine64/crc32_combine_gen64 に len2 < 0 の番人を足した"
