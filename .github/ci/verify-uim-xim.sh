#!/bin/sh
# inputmethod/uim の xim option を切ると建たない件を、再現してから直して見せる。
#
#   sh verify-uim-xim.sh <カテゴリ>/<パッケージ>
#
# #153 (PLIST の重複) とは別の、同じ options.mk の欠陥である。切った側の枝が
# こうなっている。
#
#	.if !empty(PKG_OPTIONS:Mxim)
#	.include "../../x11/libXft/buildlink3.mk"
#	.include "../../x11/libX11/buildlink3.mk"
#	.include "../../x11/libXext/buildlink3.mk"
#	CONFIGURE_ARGS+=	--with-x
#	.else
#	SUBST_CLASSES+=		xim
#	SUBST_STAGE.xim=	pre-configure
#	SUBST_FILES.xim=	configure
#	SUBST_SED.xim=		-e 's;use_xim="yes";use_xim="no";g'
#	.endif
#
# 順に潰していくと、四行ごと要らないことと、PLIST にも手が要ることが分かる。
#
# 一つめ、時機。uim は configure を生成する package で、Makefile.common の
# pre-configure が autogen.sh を走らせる。subst.mk は SUBST_STAGE で名指し
# された target の前提として繋がる (mk/subst.mk:161) ので、pre-configure の
# 中身より先に走り、その時点で configure はまだ無い。
#
#	ERROR: [subst.mk:xim] The filename pattern "configure" has no effect.
#
# 二つめ、探している文字列。時機を do-configure-pre-hook へ送って configure が
# 在る状態にしても、当たらない。
#
#	WARNING: [subst.mk:xim] Nothing changed in "configure".
#
# pkgsrc が固定している uim (0dd88f7) に use_xim="yes" は一箇所も無い。
#
#	configure.ac:334    PKG_CHECK_MODULES(XIM, xext, use_xim=yes, use_xim=no)
#	configure:25467             use_xim=yes
#
# 引用符が付いていない。生成される側も m4 の引数をそのまま写すので、どちらにも
# 無い。この SED はどの段で走らせても当たらない。
#
# 三つめ、当てても足りない。SED を直して subst.mk が黙っても、建たない。
#
#	uim-x-util.c:34:10: fatal error: X11/Xlib.h: No such file or directory
#
# use_xim を no にしても configure の have_x は yes のままだからである。
# AC_PATH_XTRA が buildlink の外の /usr/X11R7 を直に見つける。X を使う部分は
# 有効なまま組まれ、header は buildlink に無い。切った枝は libX11 も libXft も
# libXext も外しているので、当然そうなる。
#
# つまり use_xim を触るのが間違いで、have_x を落とさなければいけない。
#
#	use_xim=no
#	if test x"$have_x" != xdisabled && test x"$have_x" != xno; then
#	  PKG_CHECK_MODULES(XIM, xext, use_xim=yes, use_xim=no)
#
# have_x が disabled なら use_xim は no のままである。そして have_x を
# disabled にする口は AC_PATH_XTRA が持っている。--without-x である。専用の
# --enable-xim は無いが、切った枝が欲しいのは「X ごと使わない」ことなので、
# これがそのまま答えになる。入れた枝が既に --with-x を渡しているので対になる。
#
# 四つめ、PLIST。--without-x で組めるようになると、今度は file-check が並べる。
#
#	ERROR: ... in the PLIST but not in .../work/.destdir/usr/pkg:
#	ERROR:         .../bin/uim-xim
#	ERROR:         .../lib/uim/plugin/libuim-xkb.la
#	ERROR:         .../man/man1/uim-xim.1
#
# options.mk は gtk2 gtk3 gtk4 qt5 qt6 のどれにも PLIST.<option> を持っている
# のに、xim にだけ無い。X が要る三つが素の PLIST に置いたままである。
# (share/uim/xkb.scm は X が無くても入るので動かさない。)
#
# 直しは同じ file の中に手本が在る形になる。
#
#	.if !empty(PKG_OPTIONS:Mxim)
#	PLIST_SRC+=		PLIST.xim
#	.include ... (今のまま)
#	CONFIGURE_ARGS+=	--with-x
#	.else
#	CONFIGURE_ARGS+=	--without-x
#	.endif
#
# 見るのは五つ。
#
#   1. 素のまま -xim で建てる       -> subst.mk のエラーで止まるはず
#   2. SUBST を直しただけで建てる   -> X11/Xlib.h で止まるはず
#   3. --without-x だけで建てる     -> PLIST の三つで止まるはず
#   4. PLIST.xim も入れて建てる     -> 通るはず
#   5. xim を入れ直して建てる       -> 通るはず。uim-xim が入ること。
#
# 2 と 3 を残してあるのは、直しの形を選んだ理由がそこだからである。測らずに
# 四行消して PLIST を割ると、消しすぎかどうかも割りすぎかどうかも分からない。
# 5 が無いと、切った側だけ直して入れた側を壊していても気付かない。
#
# 4 と 5 では #153 の直しも当てる。素の PLIST が PLIST.gtk2 と PLIST.gtk3 の
# 中身を重ねて持っているので、gtk を切ったまま package を作るとそちらでも
# 止まる。二つは別の欠陥だが、同時に直さないと -xim を最後まで通せない。

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
# LIBRSVG_TYPE は既定のまま触らない。Rust の librsvg を避けようとして
# c を指していたが、gtk4 と qt6 が入る既定の組では依存が librsvg-2.60 を
# 連れてきて、buildlink が <2.41 を要求して噛み合わずに止まる。バイナリ
# 集合に 2.60 が在るので素から建てる心配はもともと無い。
MKARGS=""
[ -n "${BINPKG_SITES:-}" ] &&
	MKARGS="DEPENDS_TARGET=bin-install BINPKG_SITES=$BINPKG_SITES"

OFF="-xim -gtk2 -gtk3 -gtk4 -qt5 -qt6"
ON="xim -gtk2 -gtk3 -gtk4 -qt5 -qt6"

cd "$TREE/$PKG" || { echo "FAIL: $TREE/$PKG が無い"; exit 1; }
rc=0
echo "--- $PKG ($OS $(uname -r) / $(uname -m)) ---"
cp options.mk /tmp/uim-options.orig
cp PLIST /tmp/uim-PLIST.orig
rm -f /tmp/uim-PLIST.xim

restore() {
	cp /tmp/uim-options.orig options.mk
	cp /tmp/uim-PLIST.orig PLIST
	rm -f PLIST.xim
}

# 一回分。$2 が option の組。
#
# install で回す。package だけだと DESTDIR の中に作って終わりで、
# /usr/pkg には何も置かない。それに気付かず $PREFIX/bin/uim-xim を見て
# 「入っていない」と読んでいた。何も入っていないのだから当たり前で、
# 切った側の検分が丸ごと空になっていた。install は PLIST の突き合わせも
# するので、file-check はこちらでも同じように出る。
build() {
	_tag=$1; _opt=$2
	pkg_delete -f uim > /dev/null 2>&1 || true
	$PKGMAKE clean > /dev/null 2>&1
	{ $PKGMAKE $MKARGS PKG_OPTIONS.uim="$_opt" install 2>&1; echo $? > /tmp/x-rc; } \
		> "/tmp/xim-$_tag.log" 2>&1
	return "$(cat /tmp/x-rc)"
}

# 建った後に、配れる形にもなるかを見る。install が通っても package が
# 通るとは限らない。
package_too() {
	_tag=$1; _opt=$2
	if $PKGMAKE $MKARGS PKG_OPTIONS.uim="$_opt" package \
			> "/tmp/xim-$_tag-pkg.log" 2>&1; then
		echo "  ok: make package も通る"
		return 0
	fi
	echo "FAIL: make package が落ちた"
	tail -25 "/tmp/xim-$_tag-pkg.log"
	return 1
}

# options.mk の切った枝を --without-x にする。
fix_options() {
	awk '
	/^SUBST_CLASSES\+=[ \t]*xim$/	{ s=1; print "CONFIGURE_ARGS+=\t--without-x"; next }
	s && /^SUBST_[A-Z]+\.xim=/	{ next }
					{ s=0; print }
	' options.mk > options.mk.new && mv options.mk.new options.mk
}

# 入れた枝に PLIST.xim を足し、X が要る三つを素の PLIST から移す。
fix_plist() {
	awk '
	/^\.if !empty\(PKG_OPTIONS:Mxim\)$/	{ print; print "PLIST_SRC+=\t\tPLIST.xim"; next }
						{ print }
	' options.mk > options.mk.new && mv options.mk.new options.mk

	head -1 PLIST.gtk2 > PLIST.xim
	for f in bin/uim-xim lib/uim/plugin/libuim-xkb.la man/man1/uim-xim.1; do
		echo "$f" >> PLIST.xim
	done
	grep -v -x -F -e bin/uim-xim -e lib/uim/plugin/libuim-xkb.la \
		-e man/man1/uim-xim.1 PLIST > PLIST.new && mv PLIST.new PLIST
	cp PLIST.xim /tmp/uim-PLIST.xim
}

# #153 の直し。素の PLIST から PLIST.gtk2 と PLIST.gtk3 の中身を落とす。
fix_153() {
	grep -h '^[a-z]' PLIST.gtk2 PLIST.gtk3 | sort -u > /tmp/dup.txt
	awk 'NR==FNR{d[$0]=1;next} !($0 in d)' /tmp/dup.txt PLIST > PLIST.new &&
		mv PLIST.new PLIST
	echo "  (#153 の直し: $(wc -l < /tmp/dup.txt) 行を素の PLIST から落とした)"
}

# ------------------------------------------------------------------
echo
echo "########## 1. 素のまま -xim で建てる ##########"
grep -nB5 -A5 'SUBST_CLASSES+=.*xim' options.mk
if build plain "$OFF"; then
	echo 'RESULT 素のまま: 通った'; echo '!! 読みが外れている。'; rc=1
elif grep -q 'subst.mk:xim' /tmp/xim-plain.log; then
	echo 'RESULT 素のまま: subst.mk のエラーで止まった (報告のとおり)'
	grep -n 'Substituting "xim"\|subst.mk:xim' /tmp/xim-plain.log | head -4
else
	echo 'RESULT 素のまま: 別の理由で落ちた (再現になっていない)'
	tail -25 /tmp/xim-plain.log; rc=1
fi

# ------------------------------------------------------------------
echo
echo "########## 2. SUBST を直しただけでは足りない ##########"
restore
sed -e 's|^SUBST_STAGE.xim=[[:space:]]*pre-configure$|SUBST_STAGE.xim=\tdo-configure-pre-hook|' \
    -e 's|use_xim="yes";use_xim="no"|use_xim=yes;use_xim=no|' \
	options.mk > options.mk.new && mv options.mk.new options.mk
grep -nA4 'SUBST_CLASSES+=.*xim' options.mk
if build subst "$OFF"; then
	echo 'RESULT SUBST を直した: 通った'; echo '!! 読みが外れている。'; rc=1
elif grep -q 'X11/Xlib.h' /tmp/xim-subst.log; then
	echo 'RESULT SUBST を直した: X11/Xlib.h で止まった (use_xim だけでは足りない)'
	grep -q 'subst.mk:xim' /tmp/xim-subst.log &&
		echo "  !! subst.mk はまだ苦情を言っている" ||
		echo "  ok: subst.mk は黙った。それでも建たない。"
	grep -n 'X11/Xlib.h' /tmp/xim-subst.log | head -2
else
	echo 'RESULT SUBST を直した: 別の理由で落ちた'
	tail -25 /tmp/xim-subst.log; rc=1
fi

# ------------------------------------------------------------------
echo
echo "########## 3. --without-x だけ。PLIST が残ることを見る ##########"
restore
fix_options
fix_153
if build nox "$OFF"; then
	echo 'RESULT --without-x だけ: 通った'
	echo '!! PLIST に手が要らないなら、PLIST.xim を作る理由が無い。'
	rc=1
elif grep -q 'in the PLIST but not in' /tmp/xim-nox.log; then
	echo 'RESULT --without-x だけ: 組めたが PLIST で止まった'
	echo "--- 並べたのに無いもの ---"
	sed -n '/in the PLIST but not in/,/^\*\*\*/p' /tmp/xim-nox.log |
		grep '^ERROR:' | sed -e 's;.*/usr/pkg/;;' | grep -v 'in the PLIST'
else
	echo 'RESULT --without-x だけ: 別の理由で落ちた'
	tail -30 /tmp/xim-nox.log; rc=1
fi

# ------------------------------------------------------------------
echo
echo "########## 4. PLIST.xim も入れて -xim で建てる ##########"
restore
fix_options
fix_153
fix_plist
echo "--- options.mk の xim の枝 ---"
grep -nA9 '^\.if !empty(PKG_OPTIONS:Mxim)' options.mk
echo "--- PLIST.xim ---"; cat PLIST.xim
if build off "$OFF"; then
	echo 'RESULT 直したあと (-xim): 通った'
	echo "--- configure の結論 ---"
	grep -nE 'XIM +:' /tmp/xim-off.log | tail -2
	grep -qE 'XIM +: *no' /tmp/xim-off.log &&
		echo "  ok: configure は XIM : no と言っている" ||
		{ echo "FAIL: XIM : no が出ていない"; rc=1; }
	[ -e "$PREFIX/bin/uim-xim" ] &&
		{ echo "FAIL: uim-xim が在る"; rc=1; } ||
		echo "  ok: uim-xim は入っていない"
	if ldd "$PREFIX/lib/libuim.so" 2>/dev/null | grep -q X11; then
		echo "FAIL: libuim が libX11 を掴んでいる"; rc=1
	else
		echo "  ok: libuim は libX11 を掴んでいない"
	fi
	echo '(display (uim-version))' | "$PREFIX/bin/uim-sh" 2>&1 | head -3
	"$PREFIX/bin/uim-module-manager" --list 2>&1 | head -4
	package_too off "$OFF" || rc=1
else
	echo 'RESULT 直したあと (-xim): 落ちた'
	tail -40 /tmp/xim-off.log; rc=1
fi

# ------------------------------------------------------------------
echo
echo "########## 5. xim を入れ直す。切った側だけ直して壊していないか ##########"
if build on "$ON"; then
	echo 'RESULT 直したあと (xim): 通った'
	grep -nE 'XIM +:' /tmp/xim-on.log | tail -2
	grep -qE 'XIM +: *yes' /tmp/xim-on.log &&
		echo "  ok: configure は XIM : yes と言っている" ||
		{ echo "FAIL: XIM : yes が出ていない"; rc=1; }
	[ -e "$PREFIX/bin/uim-xim" ] &&
		echo "  ok: uim-xim が入っている" ||
		{ echo "FAIL: uim-xim が無い。PLIST.xim が効いていない。"; rc=1; }
	[ -e "$PREFIX/lib/uim/plugin/libuim-xkb.la" ] &&
		echo "  ok: libuim-xkb.la が入っている" ||
		{ echo "FAIL: libuim-xkb.la が無い"; rc=1; }
	echo '(display (uim-version))' | "$PREFIX/bin/uim-sh" 2>&1 | head -3
	package_too on "$ON" || rc=1
else
	echo 'RESULT 直したあと (xim): 落ちた'
	tail -40 /tmp/xim-on.log; rc=1
fi

restore
$PKGMAKE clean > /dev/null 2>&1

[ $rc -eq 0 ] && echo "=== 通った: $PKG on $OS ===" ||
	echo "=== 見込みと違った: $PKG on $OS ==="
exit $rc
