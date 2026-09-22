#!/bin/sh
# GO_TYPE を木に入れる。go-bin の側は zakinko/go-bin をそのまま写すので、
# fork と木で中身が食い違うことがない。version.mk だけ差分を当てる。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)

if grep -q 'GO_BIN_SUPPORTED' "$TREE/lang/go/version.mk"; then
	echo "  go: version.mk は既に GO_TYPE を見ている。何もしない"
	exit 0
fi

# go-bin を fork の中身に入れ替える (PR 一本目ぶん)
for f in Makefile distinfo platforms.mk; do
	cp "$TREE/zakinko/go-bin/$f" "$TREE/lang/go-bin/$f"
done
grep -q 'GO_BIN_PLATFORMS' "$TREE/lang/go-bin/platforms.mk" || {
	echo "!! go-bin: platforms.mk が入っていない" >&2; exit 1; }

patch -f -p0 -d "$TREE" -i "$D/tree-go-type.diff" > /dev/null
grep -q 'GO_BIN_SUPPORTED' "$TREE/lang/go/version.mk" || {
	echo "!! go: version.mk に GO_TYPE が入っていない" >&2; exit 1; }
echo "  go: go-bin を fork の中身にし、version.mk に GO_TYPE を入れた"
