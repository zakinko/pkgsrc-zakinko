#!/bin/sh
# RUST_TYPE=bin を、rust-bin が binary を持たない platform で黙って src へ
# 落とす。一覧は lang/rust/platform.mk に一本化し、lang/rust-bin/Makefile は
# そこから ONLY_FOR_PLATFORM を作る。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)
if grep -q 'PLATFORM_SUPPORTS_RUST_BIN' "$TREE/lang/rust/platform.mk"; then
	echo "  rust: platform.mk は既に rust-bin を見ている。何もしない"
	exit 0
fi
patch -f -p0 -d "$TREE" -i "$D/tree-rust-type.diff" > /dev/null
for c in 'lang/rust/platform.mk:PLATFORM_SUPPORTS_RUST_BIN' \
         'lang/rust/rust.mk:PLATFORM_SUPPORTS_RUST_BIN' \
         'lang/rust-bin/Makefile:RUST_BIN_PLATFORMS'; do
	f=${c%%:*}; k=${c#*:}
	grep -q "$k" "$TREE/$f" || { echo "!! rust: $f に $k が入っていない" >&2; exit 1; }
done
echo "  rust: RUST_TYPE=bin を rust-bin の無い platform で src に落とすようにした"
