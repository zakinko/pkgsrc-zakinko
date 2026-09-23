#!/bin/sh
# devel/pkgconf に unveil の順序の直しを置く。送る diff と同じ物。
#
# pkgconf 3.0.7 は cli/main.c で audit log の path を unveil してから
# 開く。unveil は最初の一回で filesystem 全体を閉じるので、その後に
# 探索路を並べる lstat が全部失敗し、見えない dir は黙って捨てられる
# (libpkgconf/path.c:84)。pkgsrc は PKG_CONFIG_LOG を常に立てるため、
# OpenBSD ではどの .pc も NOT-FOUND になる。さらに cli/core.c は
# /dev/null の fopen の結果を見ずに flag を立てるので、終了時の
# fclose が NULL を掴んで SIGSEGV する。configure が
#
#	checking pkg-config is at least version 0.9.0... Segmentation fault
#
# で止まるのはこれ。log を何も unveil されていないうちに開き、fopen の
# 結果を見てから flag を立てる。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)
if [ -f "$TREE/devel/pkgconf/patches/patch-cli_main.c" ]; then
	echo "  pkgconf: 既に当て物が在る。何もしない"
	exit 0
fi
# -F0 が要る。patch -C は既定で fuzz を許し、文脈が変わっていても通る。
patch -C -f -F0 -p0 -d "$TREE" -i "$D/tree-pkgconf-openbsd.diff" < /dev/null > /dev/null \
	|| { echo "!! pkgconf: 空当てが通らない" >&2; exit 1; }
patch -f -p0 -d "$TREE" -i "$D/tree-pkgconf-openbsd.diff" < /dev/null > /dev/null
grep -q 'unveil' "$TREE/devel/pkgconf/patches/patch-cli_main.c" \
	|| { echo "!! pkgconf: 当たっていない" >&2; exit 1; }
rm -f "$TREE"/devel/pkgconf/patches/*.orig "$TREE"/devel/pkgconf/patches/*.rej
echo "  pkgconf: cli/main.c と cli/core.c に unveil の順序の直しを足した"
