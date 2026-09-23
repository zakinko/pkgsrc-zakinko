#!/bin/sh
# security/openssl に、aarch64 の stitched AES+SHA の定数を .rodata へ
# 移す上流の直しを当てる。送る diff と同じ物。
#
# 3.6.4 は round 定数を .text の中に置き、adr で番地を取って ldp で読む。
# OpenBSD/arm64 の .text は実行のみで読めないので、その ldp で SIGSEGV
# する (test/recipes/30-test_evp.t)。上流は f7feb2d937ac (2025-10-01、
# "[aarch64] move constants to rodata") で定数を .rodata へ移し、adr を
# adrp + add :lo12: に変えたが、3.6 枝には入っていない。
#
# 生成される code が aarch64 全般で変わるので PKGREVISION も上げる。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)
if [ -f "$TREE/security/openssl/patches/patch-crypto_aes_asm_aes-sha1-armv8.pl" ]; then
	echo "  openssl-asm: 既に当て物が在る。何もしない"
	exit 0
fi
# -F0 が要る。空当ては既定で fuzz を許し、文脈が変わっていても通る。
patch -C -f -F0 -p0 -d "$TREE" -i "$D/tree-openssl-asm-rodata.diff" < /dev/null > /dev/null \
	|| { echo "!! openssl-asm: 空当てが通らない" >&2; exit 1; }
patch -f -p0 -d "$TREE" -i "$D/tree-openssl-asm-rodata.diff" < /dev/null > /dev/null
rm -f "$TREE"/security/openssl/patches/*.orig "$TREE"/security/openssl/*.orig
n=$(grep -c 'adrp' "$TREE/security/openssl/patches/patch-crypto_aes_asm_aes-sha1-armv8.pl" || true)
[ "${n:-0}" -gt 0 ] || { echo "!! openssl-asm: 当たっていない" >&2; exit 1; }
echo "  openssl-asm: aarch64 の定数を .rodata へ移す上流の直しを足した"
