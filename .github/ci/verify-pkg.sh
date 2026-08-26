#!/bin/sh
# 専用の検査を持たないパッケージ向けの、最低限の確かめ。
#
#   sh verify-pkg.sh <パッケージ名>
#
# mule には verify-mule.sh がある。日本語が編集できるところまで踏まないと
# 「通った」と言えない相手だからで、自作の三つはそこまで要らない。組めて、
# 入って、PLIST どおりのものが置かれて、外せる。そこまで見る。
#
# 自作パッケージの distinfo は追跡していない (README の方針)。無ければ
# その場で makesum する。第三者から引き取った mule だけは distinfo を
# 持っているので、この道は通らない。

PKG=$1
[ -n "$PKG" ] || { echo "usage: $0 <パッケージ名>"; exit 1; }

OS=$(uname -s)
# 呼ぶ側 (build-on-bsd.sh) が置き場所を決めて渡してくる。Darwin は /usr が
# 書けないので /opt/pkg になる。単体で走らせたときのために既定も持つ。
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}

PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
PATH=$PATH:/usr/X11R7/bin:/usr/X11R6/bin:/usr/local/bin
export PATH
unset PKG_PATH

# 名前だけなら自作カテゴリ、<カテゴリ>/<パッケージ> なら上流のそこを見る。
# build-on-bsd.sh の OVERLAY_PKGS から呼べなかったのはこの一行のせいだった。
case $PKG in
*/*)	DIR=$TREE/$PKG ;;
*)	DIR=$TREE/zakinko/$PKG ;;
esac
# pkg_info や pkg_delete に渡すのはパッケージ名だけ。
PKGBASE=${PKG##*/}

if [ "$OS" = NetBSD ]; then
	PKGMAKE=make
	MKARGS=
else
	# base の make は pkgsrc には使えない。bootstrap が入れた bmake を呼ぶ。
	PKGMAKE=$PREFIX/bin/bmake
	MKARGS="DEPENDS_TARGET=package-install"
fi

# 依存は在ればバイナリで引く。
#
# これが無くて zls が LLVM を素から組み始めた。lang/zig -> lang/clang ->
# lang/llvm と辿って llvm-project-21.1.8 を建て、当然のように時間切れに
# なる。見たいのは zls が組めるかであって、LLVM が組めるかではない。
#
# BINPKG_SITES を渡すと bin-install が公式の集合から降ろす。PKG_PATH では
# ない。あれを設定したまま pkgsrc の make を走らせると
#
#	ERROR: [bsd.pkg.mk] Please unset PKG_PATH before doing pkgsrc work!
#
# で組む前に弾かれる。ツリーを四半期枝に合わせてあるときだけ版が噛み合う
# ので、PKGSRC_URL を current にしている相手には渡さない。
if [ -n "${BINPKG_SITES:-}" ]; then
	MKARGS="$MKARGS DEPENDS_TARGET=bin-install BINPKG_SITES=$BINPKG_SITES"
	echo "--- 依存の出どころ: $BINPKG_SITES ---"
fi

echo "--- $PKG ($OS $(uname -r) / $(uname -m)) ---"
cd "$DIR" || { echo "FAIL: $DIR が無い"; exit 1; }

if [ ! -f distinfo ]; then
	echo "--- distinfo が無いので makesum ---"
	$PKGMAKE $MKARGS makesum || { echo "FAIL: makesum できない"; exit 1; }
fi

# 相手にしていない OS は、転けたのではなく対象外。nss_stns がそれで、
# ONLY_FOR_PLATFORM に NetBSD と FreeBSD と DragonFly と MidnightBSD しか
# 書いていない。名前解決の差し込み方が OS ごとに違うためで、Linux 側は
# glibc の NSS 向けに upstream が別の実装を持っている。ここでその別実装を
# 組もうとしても意味がないので、飛ばしたと分かる形で終わる。
# pkgsrc は弾く理由を PKG_FAIL_REASON に入れる。組み始める前に訊く。
if $PKGMAKE show-vars VARNAMES=PKG_FAIL_REASON 2>/dev/null |
   grep -qi 'not available'; then
	echo "SKIP: $PKG は $OS を相手にしていない (ONLY_FOR_PLATFORM)"
	$PKGMAKE show-vars VARNAMES=ONLY_FOR_PLATFORM 2>/dev/null | sed 's/^/    /'
	exit 0
fi

# 作り直しのときに古いものが残っていると install が拒まれる。
pkg_delete -f "$PKGBASE" > /dev/null 2>&1 || true

echo "--- build と install ---"
if ! $PKGMAKE $MKARGS install > /tmp/verify-$PKGBASE.log 2>&1; then
	if grep -qi 'not available for this platform' /tmp/verify-$PKGBASE.log; then
		echo "SKIP: $PKG は $OS を相手にしていない (ONLY_FOR_PLATFORM)"
		exit 0
	fi
	tail -30 /tmp/verify-$PKGBASE.log
	echo "FAIL: $PKG が入らない"
	exit 1
fi
tail -5 /tmp/verify-$PKGBASE.log

echo "--- 入ったものを見る ---"
pkg_info -e "$PKGBASE" || { echo "FAIL: pkg_info が $PKGBASE を知らない"; exit 1; }
pkg_info -L "$PKGBASE" | sed -n '1,15p'

# PLIST に並べたものが実際に置かれたか。pkg_add は並んでいない物を入れない
# ので、ここで見るのは「並べたのに無い」ほう。
miss=0
for f in $(pkg_info -qL "$PKGBASE" 2>/dev/null); do
	[ -e "$f" ] || { echo "    無い: $f"; miss=$((miss + 1)); }
done
[ $miss -eq 0 ] || { echo "FAIL: $miss 個が置かれていない"; exit 1; }

echo "--- 外せるか ---"
$PKGMAKE deinstall > /dev/null 2>&1 || pkg_delete "$PKGBASE" > /dev/null 2>&1 || {
	echo "FAIL: $PKG が外せない"; exit 1; }

echo "=== 通った: $PKG on $OS ==="
