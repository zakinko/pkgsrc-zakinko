#!/bin/sh
# lang/rust-bin が Darwin/x86_64 で install できない。fix-darwin-install-name が
# lib/rustlib/<target>/lib の dylib の install name を絶対 path に書き換えよう
# として、Mach-O の header の余白に収まらない。
#
# 手元の macOS で上流の配布物に実際に install_name_tool を打って測った値:
#
#	arch      元の id  通る最大  必要   結果
#	x86_64      36 字     71 字   74 字  入らない (3 字足りない)
#	aarch64     36 字     87 字   75 字  入る
#
# しかも install_name_tool はこの error を出して exit 0 する。build は止まらず、
# ずっと後で pkg_add が missing required library: @rpath/... で落ちる。
#
# 書き換えは実行のためには要らない。bin/rustc は LC_RPATH @loader_path/../lib を
# 持ち、${PREFIX}/bin/../lib = ${PREFIX}/lib で dylib に届く。rustlib の下の
# dylib も同じ。そしてどの dylib も自分以外の @rpath 依存を持たないので
# -change の輪は元から無効打だった (x86_64 と aarch64 の両方で数えた)。
#
# 送る diff そのもの。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)
M=$TREE/lang/rust-bin/Makefile

# 上流が先に直していたら何もしない。深い path が .for の一覧から消えている
# ことで見る。
if ! grep -q 'for lib in lib lib/rustlib/${RUST_ARCH}/lib ${DESTDIR}' "$M" 2>/dev/null &&
   grep -q 'CHECK_SHLIBS_SKIP+=	lib/rustlib' "$M"; then
	echo "  rust-bin (darwin): 上流に追いついている。何もしない"
	exit 0
fi

patch -f -p0 -d "$TREE" < "$D/tree-rust-bin-darwin.diff" > /dev/null

# 当たった印。Darwin の腕の .for が lib だけになり、CHECK_SHLIBS_SKIP が
# 足されていること。非 Darwin の patchelf 側の .for は残っていなければならない
# ので、そちらも数える — 両方消すと Linux が黙って壊れる。
grep -q '^\.  for lib in lib$' "$M" || {
	echo "!! rust-bin (darwin): Darwin の .for が lib だけになっていない" >&2; exit 1; }
grep -q 'CHECK_SHLIBS_SKIP+=	lib/rustlib/\*/lib/\*\.dylib' "$M" || {
	echo "!! rust-bin (darwin): CHECK_SHLIBS_SKIP が入っていない" >&2; exit 1; }
grep -q 'for lib in lib lib/rustlib/${RUST_ARCH}/lib' "$M" || {
	echo "!! rust-bin (darwin): 非 Darwin 側の .for まで消えている" >&2; exit 1; }
grep -q 'install_name_tool did not set' "$M" || {
	echo "!! rust-bin (darwin): -id が効いたことの確認が入っていない" >&2; exit 1; }
# CHECK_SHLIBS_SKIP は Darwin の腕の中、bsd.prefs.mk より後に置く。最初は
# 45 行目 (prefs は 67 行目) に置いて
#	bmake: Malformed conditional '${OPSYS} == "Darwin"'
# で macOS を両方落とした。:U では直らない -- 常に偽になって手当てが黙って
# 効かなくなる。位置そのものを数える。
sh "$D/check-mk-vars-after-prefs.sh" "$M" || exit 1
echo "  rust-bin (darwin): 深い install name の書き換えをやめた"
