#!/bin/sh
# GO_TYPE を木に入れる。go-bin の側は zakinko/go-bin をそのまま写すので、
# fork と木で中身が食い違うことがない。version.mk だけ差分を当てる。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)

if grep -q 'PLATFORM_SUPPORTS_GO_BIN' "$TREE/lang/go/version.mk"; then
	echo "  go: version.mk は既に GO_TYPE を見ている。何もしない"
	exit 0
fi

# go-bin を fork の中身に入れ替える (PR 一本目ぶん)。
#
# 取り元は repo の go-bin であって $TREE/zakinko/go-bin ではない。
# build-on-bsd.sh は TREE_PATCH を bootstrap の前に当て、zakinko カテゴリを
# 重ねるのはその後なので、当てる時点では $TREE/zakinko はまだ空。
# repo の根は この script の在処から辿る (.github/ci の二つ上)。
SRC=$(cd "$D/../.." && pwd)/go-bin
[ -d "$SRC" ] || { echo "!! go-bin が repo に無い: $SRC" >&2; exit 1; }
for f in Makefile distinfo platform.mk; do
	cp "$SRC/$f" "$TREE/lang/go-bin/$f"
done
grep -q 'GO_BIN_PLATFORMS' "$TREE/lang/go-bin/platform.mk" || {
	echo "!! go-bin: platform.mk が入っていない" >&2; exit 1; }

patch -f -p0 -d "$TREE" -i "$D/tree-go-type.diff" > /dev/null
grep -q 'PLATFORM_SUPPORTS_GO_BIN' "$TREE/lang/go/version.mk" || {
	echo "!! go: version.mk に GO_TYPE が入っていない" >&2; exit 1; }
sh "$D/check-mk-structure.sh" "$TREE/lang/go/version.mk" || exit 1

# GO_TYPE は user が mk.conf に書く変数なので、mk/defaults/mk.conf にも載せる。
# RUST_TYPE がそうしている (1347 行の #RUST_TYPE?= src)。載せないと、査読で
# 最初に指摘される所になる。
patch -f -p0 -d "$TREE" -i "$D/tree-go-type-mkconf.diff" > /dev/null
grep -q '^#GO_TYPE?=' "$TREE/mk/defaults/mk.conf" || {
	echo "!! mk.conf に GO_TYPE が入っていない" >&2; exit 1; }
# 並びは alphabet 順。GAMEOWN < GO_TYPE < GRUB_NETWORK_CARDS を数える。
_a=$(grep -n '^GAMEOWN?=' "$TREE/mk/defaults/mk.conf" | cut -d: -f1)
_g=$(grep -n '^#GO_TYPE?=' "$TREE/mk/defaults/mk.conf" | cut -d: -f1)
_r=$(grep -n '^#GRUB_NETWORK_CARDS=' "$TREE/mk/defaults/mk.conf" | cut -d: -f1)
if [ -z "$_a" ] || [ -z "$_g" ] || [ -z "$_r" ] ||
   [ "$_a" -ge "$_g" ] || [ "$_g" -ge "$_r" ]; then
	echo "!! mk.conf の並びが alphabet 順でない (GAMEOWN=$_a GO_TYPE=$_g GRUB=$_r)" >&2
	exit 1
fi
echo "  go: go-bin を fork の中身にし、version.mk と mk.conf に GO_TYPE を入れた"
