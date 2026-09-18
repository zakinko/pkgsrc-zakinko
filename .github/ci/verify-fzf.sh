#!/bin/sh
# sysutils/fzf を GO_TYPE=bin で建てて、lang/go-bin が toolchain として
# 使われたことを実機で見る。
#
#   sh verify-fzf.sh sysutils/fzf
#
# build-on-bsd.sh が TREE_PKGS から名前で引いて呼ぶ。木には
# tree-patch-go-type.sh が先に当たっている前提。fzf を選んだのは
# go-module.mk を使う小さい package で、go.mod の go directive が
# 1.23.0 だから (0.74.4。toolchain の版に関係なく建つ)。
#
# 見るのは四つ。
#   1. mk.conf に GO_TYPE=bin を書くと TOOL_DEPENDS が go-bin だけになる
#      (go1xx を要求しない)。書かなければ今までどおり go1xx
#   2. 建つ。go-bin が上流の tarball から入る
#   3. 入った go-bin が Makefile の版 (1.27.1) を名乗り、この platform を名乗る
#   4. fzf の binary が go-bin の版で建っている (go version <binary>)
set -e
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
BMAKE=$PREFIX/bin/bmake
PKG=${1:-sysutils/fzf}
GO=$PREFIX/go-bin/bin/go

cd "$TREE/$PKG"
want=$(sed -n 's/^PKGNAME=[[:space:]]*go-bin-//p' "$TREE/lang/go-bin/Makefile")
echo "== go-bin in tree: $want   platform: $($BMAKE show-var VARNAME=MACHINE_PLATFORM)"

echo "== TOOL_DEPENDS, GO_TYPE unset (src):"
$BMAKE show-var VARNAME=TOOL_DEPENDS | tr ' ' '\n' | grep '^go' || true

MKCONF=$PREFIX/etc/mk.conf
[ -f "$MKCONF" ] || MKCONF=/etc/mk.conf
grep -q '^GO_TYPE=' "$MKCONF" || printf 'GO_TYPE=\tbin\n' >> "$MKCONF"

echo "== TOOL_DEPENDS, GO_TYPE=bin in $MKCONF:"
deps=$($BMAKE show-var VARNAME=TOOL_DEPENDS)
echo "$deps" | tr ' ' '\n' | grep '^go' || true
echo "$deps" | grep -q 'go-bin>=' || { echo "!! go-bin が依存に出ない" >&2; exit 1; }
echo "$deps" | grep -q 'go1[0-9][0-9]-' && { echo "!! go1xx も要求している" >&2; exit 1; }
echo "== GO: $($BMAKE show-var VARNAME=GO)"

$BMAKE install

echo "== go-bin says:"; "$GO" version
"$GO" version | grep -q "go$want " || { echo "!! go-bin の版が $want でない" >&2; exit 1; }
echo "== fzf built with:"; "$GO" version "$PREFIX/bin/fzf"
"$GO" version "$PREFIX/bin/fzf" | grep -q "go$want\$" || { echo "!! fzf が go-bin で建っていない" >&2; exit 1; }
echo "== fzf runs:"; "$PREFIX/bin/fzf" --version
if ls -d "$PREFIX"/go1[0-9][0-9] >/dev/null 2>&1; then
	echo "!! go1xx が入っている: $(ls -d "$PREFIX"/go1[0-9][0-9])" >&2; exit 1
fi
echo "== ok: $PKG built with go-bin-$want on $(uname -s) $(uname -m)"
