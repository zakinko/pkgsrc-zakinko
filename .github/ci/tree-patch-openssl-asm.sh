#!/bin/sh
# security/openssl に、aarch64 の stitched AES+SHA の定数を .rodata へ
# 移す上流の直しを当てる。送る diff (tree-openssl-asm-rodata.diff) と
# 同じ物を使う。
#
# 3.6.4 は round 定数を .text の中に置き、adr で番地を取って ldp で読む。
# OpenBSD/arm64 の .text は実行のみで読めないので、その ldp で SIGSEGV
# する (test/recipes/30-test_evp.t)。上流は f7feb2d937ac (2025-10-01、
# "[aarch64] move constants to rodata") で定数を .rodata へ移し、adr を
# adrp + add :lo12: に変えたが、3.6 枝には入っていない。
#
# 生成される code が aarch64 全般で変わるので PKGREVISION も上げる。
#
# distinfo だけは patch で当てない。BSD-nodef-aarch64 の当て物も同じ file に
# SHA1 行を足すので、どちらを先に当てても後の hunk は文脈が合わなくなる。
# 送る diff は素の木に当たる形のまま置き、ここでは行を挿す。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)
DIFF=$D/tree-openssl-asm-rodata.diff
P=$TREE/security/openssl/patches
if [ -f "$P/patch-crypto_aes_asm_aes-sha1-armv8.pl" ]; then
	echo "  openssl-asm: 既に当て物が在る。何もしない"
	exit 0
fi

T=${TMPDIR:-/tmp}/oasm.$$
rm -rf "$T"; mkdir -p "$T"
# diff を当てる先ごとに切り、distinfo の分だけ除ける。
awk -v out="$T" '
	/^--- /{ n++; f = sprintf("%s/%03d.diff", out, n); tgt[n] = "" }
	/^\+\+\+ /{ tgt[n] = $2 }
	{ if (n) print > f }
	END { for (i = 1; i <= n; i++) printf "%03d %s\n", i, tgt[i] }
' "$DIFF" > "$T/index"

while read -r num tgt; do
	case "$tgt" in
	*/distinfo) continue ;;
	esac
	patch -C -f -F0 -p0 -d "$TREE" -i "$T/$num.diff" < /dev/null > /dev/null \
		|| { echo "!! openssl-asm: $tgt の空当てが通らない" >&2; rm -rf "$T"; exit 1; }
	patch -f -p0 -d "$TREE" -i "$T/$num.diff" < /dev/null > /dev/null
done < "$T/index"
rm -rf "$T"
rm -f "$P"/*.orig "$TREE"/security/openssl/*.orig

# distinfo に SHA1 行を足す。値は当て物そのものから取る ($NetBSD$ 行を除く)。
for f in "$P"/patch-crypto_aes_asm_*; do
	b=$(basename "$f")
	grep -q "SHA1 ($b)" "$TREE/security/openssl/distinfo" && continue
	h=$(sed '/\$NetBSD.*\$/d' "$f" | (command -v sha1 > /dev/null 2>&1 && sha1 -q || \
		(command -v sha1sum > /dev/null 2>&1 && sha1sum | cut -d' ' -f1 || \
		 openssl dgst -sha1 | sed 's/.*= *//')))
	[ -n "$h" ] || { echo "!! openssl-asm: $b の SHA1 が取れない" >&2; exit 1; }
	printf 'SHA1 (%s) = %s\n' "$b" "$h" >> "$TREE/security/openssl/distinfo"
done
# SHA1 行は名前順に並べる作法なので、その部分だけ並べ直す。
d=$TREE/security/openssl/distinfo
grep -v '^SHA1 (' "$d" > "$d.head"
grep '^SHA1 (' "$d" | sort > "$d.sha"
cat "$d.head" "$d.sha" > "$d.new" && mv "$d.new" "$d"
rm -f "$d.head" "$d.sha"

n=$(grep -c 'adrp' "$P/patch-crypto_aes_asm_aes-sha1-armv8.pl" || true)
[ "${n:-0}" -gt 0 ] || { echo "!! openssl-asm: 当たっていない" >&2; exit 1; }
echo "  openssl-asm: aarch64 の定数を .rodata へ移す上流の直しを足した"
