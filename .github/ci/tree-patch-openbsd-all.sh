#!/bin/sh
# OpenBSD で pkgsrc の go を建てるのに要る、木の直し三つをまとめて当てる。
# どれも送る diff と同じ file をそのまま当てる。
#
#   tree-go-bin-openbsd.diff        lang/go-bin に openbsd-amd64/arm64、bootstrap.mk に OpenBSD
#   tree-openssl-openbsd-arm64.diff security/openssl: OpenBSD/arm64 は -z defs の無い target を選ぶ
#   tree-ncurses-openbsd.diff       devel/ncurses: configure の ldconfig -v が ld.so.hints を潰すのを止める
#   tree-openssl-asm-rodata.diff    security/openssl: aarch64 の stitched AES+SHA の定数を .rodata へ
#
# 後の二つは go の話ではないが、go-bin の perl:run と bash:run の連鎖の底に
# 居て、arm64 では openssl が建たず、amd64 でも ncurses の configure が
# ld.so.hints を /usr/lib だけにして vmactions の持ち帰りの rsync を殺していた
# (run 35153723523 の liblz4、35165804296 の libiconv)。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)
sh "$D/tree-patch-go-bin-openbsd.sh" "$TREE"
if grep -q 'BSD-nodef-aarch64' "$TREE/security/openssl/patches/patch-util_perl_OpenSSL_config.pm" 2>/dev/null; then
	echo "  openssl: 上流に追いついている。何もしない"
else
	patch -f -p0 -d "$TREE" < "$D/tree-openssl-openbsd-arm64.diff" > /dev/null
	echo "  openssl: OpenBSD/arm64 に BSD-nodef-aarch64 を選ばせる当て物二つを置いた"
fi
# aarch64 の定数を .rodata へ移す上流の backport。OpenBSD/arm64 では
# これが無いと 30-test_evp.t が SIGSEGV するが、生成される code は
# aarch64 全般で変わるので、arm64 の箱を持たない job でも当てて
# 回帰が無いことを見る (macOS の runner は arm64)。
sh "$D/tree-patch-openssl-asm.sh" "$TREE"
if grep -q 'cf_cv_ld_searchpath' "$TREE/devel/ncurses/Makefile"; then
	echo "  ncurses: 上流に追いついている。何もしない"
else
	patch -f -p0 -d "$TREE" < "$D/tree-ncurses-openbsd.diff" > /dev/null
	echo "  ncurses: CONFIGURE_ENV.OpenBSD に cf_cv_ld_searchpath=/usr/lib を足した"
fi
