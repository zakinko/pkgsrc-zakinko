#!/bin/sh
# inputmethod/uim の xim option を切ると止まる件を、再現してから直して見せる。
#
#   sh verify-uim-xim.sh <カテゴリ>/<パッケージ>
#
# #153 (PLIST の重複) とは別の、同じ options.mk の欠陥である。
#
#	ERROR: [subst.mk:xim] The filename pattern "configure" has no effect.
#
# options.mk は xim を切ると configure に SUBST を掛ける。
#
#	SUBST_CLASSES+=		xim
#	SUBST_STAGE.xim=	pre-configure
#	SUBST_FILES.xim=	configure
#	SUBST_SED.xim=		-e 's;use_xim="yes";use_xim="no";g'
#
# だが uim は configure を生成する package である。Makefile.common の
# pre-configure が autogen.sh を走らせる。SUBST の時点ではまだ無い。
# subst.mk は昔なら当たらないパターンを警告で済ませたが、今はエラーである。
#
# 直しの向きは一つしかない。上流の configure.ac に xim を切る口が無いから
# である。
#
#	use_xim=no
#	if test x"$have_x" != xdisabled && test x"$have_x" != xno; then
#	  PKG_CHECK_MODULES(XIM, xext, use_xim=yes, use_xim=no)
#
# AC_ARG_WITH も AC_ARG_ENABLE も無く、X と xext の有無だけで決まる。
# つまり configure を書き換える以外に手が無く、SUBST という手段自体は
# 妥当だった。掛ける先を、生成される configure ではなく元の configure.ac に
# 変える。autogen.sh が読む側を書き換えれば生成物に入る。
#
# 見るのは三つ。
#
#   1. 素のまま -xim で建てる  -> subst.mk のエラーで止まるはず
#   2. 対象を configure.ac にして建て直す -> 通るはず
#   3. 実際に xim が切れているか -> uim-xim が入っていないことを見る
#
# 3 を見ないと、2 は「エラーが出なくなった」だけかもしれない。SUBST が
# 当たっても中身が変わっていなければ use_xim は yes のままで、uim-xim が
# 入ってしまう。PLIST にも並んでいるので、そこで気付ける形にはなっている
# はずだが、確かめる。

PKG=${1:-inputmethod/uim}
case $PKG in */*) : ;; *) PKG=inputmethod/uim ;; esac

OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
PATH=$PATH:/usr/X11R7/bin:/usr/X11R6/bin
export PATH
unset PKG_PATH

if [ "$OS" = NetBSD ] && [ -z "${BINPKG_SITES:-}" ]; then
	_rel=$(uname -r); _br=${_rel%%.*}.0
	BINPKG_SITES=http://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/$(uname -p)/${_br}_2026Q2
fi
if [ -x "$PREFIX/bin/bmake" ]; then PKGMAKE=$PREFIX/bin/bmake
else PKGMAKE=make; fi
MKARGS="LIBRSVG_TYPE=c"
[ -n "${BINPKG_SITES:-}" ] &&
	MKARGS="$MKARGS DEPENDS_TARGET=bin-install BINPKG_SITES=$BINPKG_SITES"

# gtk は全部切る。xim の件だけを見たいので、他の option の壁を踏まない。
OPTS="-xim -gtk2 -gtk3 -gtk4 -qt5 -qt6"

cd "$TREE/$PKG" || { echo "FAIL: $TREE/$PKG が無い"; exit 1; }
rc=0
echo "--- $PKG ($OS $(uname -r) / $(uname -m)) ---"
echo "--- PKG_OPTIONS.uim=\"$OPTS\" ---"

# ------------------------------------------------------------------
echo
echo "########## 1. 素のまま -xim で建てる ##########"
grep -nA4 'SUBST_CLASSES+=.*xim' options.mk
cp options.mk /tmp/uim-options.orig
pkg_delete -f uim > /dev/null 2>&1 || true
$PKGMAKE clean > /dev/null 2>&1

{ $PKGMAKE $MKARGS PKG_OPTIONS.uim="$OPTS" install 2>&1; echo $? > /tmp/x-rc; } |
	tee /tmp/xim-1.log
if [ "$(cat /tmp/x-rc)" -eq 0 ]; then
	echo 'RESULT 素のまま: 通った'
	echo '!! 読みが外れている。切っても止まらないなら報告する必要が無い。'
	rc=1
else
	if grep -q 'subst.mk:xim' /tmp/xim-1.log; then
		echo 'RESULT 素のまま: subst.mk のエラーで止まった (報告のとおり)'
		grep -n 'subst.mk:xim' /tmp/xim-1.log | head -3
	else
		echo 'RESULT 素のまま: 別の理由で落ちた (再現になっていない)'
		tail -30 /tmp/xim-1.log
		rc=1
	fi
fi

# ------------------------------------------------------------------
echo
echo "########## 2. 対象を configure.ac にして建て直す ##########"
sed -e 's|^SUBST_FILES.xim=[[:space:]]*configure$|SUBST_FILES.xim=\tconfigure.ac|' \
	options.mk > options.mk.new && mv options.mk.new options.mk
echo "--- 直した行 ---"
grep -n 'SUBST_FILES.xim' options.mk

pkg_delete -f uim > /dev/null 2>&1 || true
$PKGMAKE clean > /dev/null 2>&1
{ $PKGMAKE $MKARGS PKG_OPTIONS.uim="$OPTS" install 2>&1; echo $? > /tmp/x-rc; } |
	tee /tmp/xim-2.log
if [ "$(cat /tmp/x-rc)" -eq 0 ]; then
	echo 'RESULT 直したあと: 通った'
else
	echo 'RESULT 直したあと: 落ちた'
	tail -40 /tmp/xim-2.log
	rc=1
fi

# ------------------------------------------------------------------
echo
echo "########## 3. 本当に xim が切れているか ##########"
# エラーが出なくなっただけかもしれない。SUBST が当たっても中身が変わって
# いなければ use_xim は yes のままである。
echo "--- configure の結論 ---"
grep -nE '^ *XIM +:' /tmp/xim-2.log | tail -2
echo "--- uim-xim が入っていないか ---"
if [ -e "$PREFIX/bin/uim-xim" ]; then
	echo "FAIL: $PREFIX/bin/uim-xim が在る。xim が切れていない。"
	rc=1
else
	echo "  ok: uim-xim は入っていない"
fi
echo "--- 動くか ---"
if [ -x "$PREFIX/bin/uim-sh" ]; then
	echo '(display (uim-version))' | "$PREFIX/bin/uim-sh" 2>&1 | head -3
else
	echo "!! uim-sh が無い"; rc=1
fi

cp /tmp/uim-options.orig options.mk
$PKGMAKE clean > /dev/null 2>&1

[ $rc -eq 0 ] && echo "=== 通った: $PKG on $OS ===" ||
	echo "=== 見込みと違った: $PKG on $OS ==="
exit $rc
