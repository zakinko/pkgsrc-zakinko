#!/bin/sh
# inputmethod/uim の PLIST が option を切ったときに合わないのを、実機で
# 再現してから直して見せる。
#
#   sh verify-uim.sh <カテゴリ>/<パッケージ>
#
# build-on-bsd.sh が OVERLAY_PKGS から名前で引いて呼ぶ。overlay/ には
# 何も置いていない。当て物のありなしを一回の実行で見たいので、直しは
# この script がその場で当てる。
#
# 何を見ているか
# --------------
# GitHub の NetBSD/pkgsrc PR #153 (afukumoto, 2025-01) は「gtk2 を切ると
# make package が転ける」というもの。options.mk は option ごとに
#
#	.if !empty(PKG_OPTIONS:Mgtk2)
#	PLIST_SRC+=	PLIST.gtk2
#
# と足す作りなのに、素の PLIST の側にも同じ 9 行が並んでいる。切ると
# 組まれていないものを PLIST が主張することになる。
#
# 経緯は追える。2019-11-01 に nia が 1.8.8 へ上げたとき、PLIST から 52 行
# 落として PLIST.gtk2 / PLIST.gtk3 / PLIST.qt5 に分けた。そこまでは正しい。
# 2021-03-30 に ryoon が 1.8.9pre20210104 へ上げたとき PLIST が +39/-1 に
# なっていて、全 option 入りで生成し直したものが入ったように見える。分けた
# ぶんが戻ってしまい、2025-11-15 の 1.9.7pre20251027 でもそのままである。
#
# PR #153 は gtk2 の 9 行だけを消している。実際は gtk3 の 9 行も同じ状態に
# あるので、ここでは PLIST.gtk2 と PLIST.gtk3 に載っている行を PLIST から
# 引く形で数える。決め打ちで 18 行と書かないのは、版が変わって顔ぶれが
# 変わったときに黙って古くなるのを避けるため。
#
# 見るのは三つ。
#
#   1. 重複がどれだけあるか            -> PLIST と PLIST.gtk* の突き合わせ
#   2. gtk2 を切って建てる (素のまま)  -> 落ちるはず
#   3. 重複を消して建て直す            -> 通るはず
#
# 2 を見ないと 3 が何を直したのか分からない。転けるのを見てから、直った
# のを見る。

PKG=${1:-inputmethod/uim}

OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}

# gtk2 だけを切る。gtk3 は残す (options.mk が gtk3 を切ると既定の toolkit を
# gtk2 に倒すので、両方切ると別の穴を踏んで #153 の再現にならない)。
# gtk4 と qt5 と qt6 は #153 と関係がなく、依存が重いだけなので落とす。
OPTS=${UIM_OPTIONS:-"-gtk2 -gtk4 -qt5 -qt6"}

PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
PATH=$PATH:/usr/X11R7/bin:/usr/X11R6/bin
export PATH
unset PKG_PATH

# NetBSD でも base の make ではなく bootstrap が入れた bmake を呼ぶ。
# build-on-bsd.sh は DISTDIR と PACKAGES と WRKOBJDIR を $PREFIX/etc/mk.conf
# に書くので、base の make (= /etc/mk.conf) で組むとキャッシュに乗らない。
if [ -x "$PREFIX/bin/bmake" ]; then
	PKGMAKE=$PREFIX/bin/bmake
	MKARGS="DEPENDS_TARGET=package-install"
elif [ "$OS" = NetBSD ]; then
	PKGMAKE=make
	MKARGS=
else
	echo "FAIL: $PREFIX/bin/bmake が無い"; exit 1
fi

DIR=$TREE/$PKG
cd "$DIR" || { echo "FAIL: $DIR が無い"; exit 1; }

rc=0
echo "--- $PKG ($OS $(uname -r) / $(uname -m)) ---"
echo "--- PKG_OPTIONS.uim=\"$OPTS\" ---"

# ------------------------------------------------------------------
echo
echo "########## 1. PLIST と PLIST.gtk* の重複を数える ##########"
: > /tmp/uim-dup.txt
for f in PLIST.gtk2 PLIST.gtk3; do
	[ -f "$f" ] || { echo "($f が無い)"; continue; }
	echo "--- $f ---"
	grep -v '^@comment' "$f" | while read -r l; do
		[ -n "$l" ] || continue
		if grep -qxF "$l" PLIST; then
			echo "  重複: $l"
			echo "$l" >> /tmp/uim-dup.txt
		fi
	done
done
ndup=$(wc -l < /tmp/uim-dup.txt | tr -d ' ')
echo "--- PLIST が PLIST.gtk* と重ねて持っている行: $ndup ---"
if [ "$ndup" -eq 0 ]; then
	echo '!! 重複が無い。上流が直したか、顔ぶれが変わっている。'
	echo '!! この検査はもう用済みかもしれない。'
	exit 1
fi

# ------------------------------------------------------------------
echo
echo "########## 2. 素のまま gtk2 を切って建てる ##########"
cp PLIST /tmp/uim-PLIST.orig
pkg_delete -f uim > /dev/null 2>&1 || true
$PKGMAKE clean > /dev/null 2>&1

if $PKGMAKE $MKARGS PKG_OPTIONS.uim="$OPTS" install > /tmp/uim-plain.log 2>&1; then
	echo 'RESULT 素のまま: 通った'
	echo '!! 読みが外れている。PLIST が合わないのに入るなら、'
	echo '!! この箱では PR #153 の問題は起きていないことになる。'
	rc=1
else
	echo 'RESULT 素のまま: 落ちた (PR #153 が言うとおり)'
fi
echo '--- PLIST の食い違いに触れている行 ---'
grep -nE 'but not installed|Files or directories|missing file|pkg_create' \
	/tmp/uim-plain.log | head -20
echo '--- 最後の 40 行 ---'
tail -40 /tmp/uim-plain.log

# ------------------------------------------------------------------
echo
echo "########## 3. 重複を消して建て直す ##########"
# PLIST.gtk2 / PLIST.gtk3 が持っている行を PLIST から落とす。option を
# 入れたときは PLIST_SRC で足されるので、消しても入るものは変わらない。
cp PLIST /tmp/uim-PLIST.before
awk 'NR==FNR { dup[$0]=1; next } !($0 in dup)' /tmp/uim-dup.txt PLIST \
	> PLIST.new && mv PLIST.new PLIST
echo "--- 消した行 ---"
diff -u /tmp/uim-PLIST.before PLIST | grep '^-' | grep -v '^---' | sed 's/^/  /'

pkg_delete -f uim > /dev/null 2>&1 || true
$PKGMAKE clean > /dev/null 2>&1
if $PKGMAKE $MKARGS PKG_OPTIONS.uim="$OPTS" install > /tmp/uim-fixed.log 2>&1; then
	echo 'RESULT 直したあと: 通った'
else
	echo 'RESULT 直したあと: 落ちた'
	tail -40 /tmp/uim-fixed.log
	rc=1
fi

# ------------------------------------------------------------------
echo
echo "########## 4. 入ったものが本当に置かれているか ##########"
if pkg_info -e uim > /dev/null 2>&1; then
	miss=0
	for f in $(pkg_info -qL uim 2>/dev/null); do
		[ -e "$f" ] || { echo "    無い: $f"; miss=$((miss + 1)); }
	done
	if [ $miss -eq 0 ]; then
		echo "PLIST に並べたものは全部置かれている"
	else
		echo "FAIL: $miss 個が置かれていない"
		rc=1
	fi
	$PKGMAKE deinstall > /dev/null 2>&1 || pkg_delete uim > /dev/null 2>&1 || true
else
	echo '(uim が入っていないので飛ばす)'
fi

# 戻す。あとの job が同じツリーを使うので、壊したままにしない。
cp /tmp/uim-PLIST.orig PLIST
$PKGMAKE clean > /dev/null 2>&1

[ $rc -eq 0 ] && echo "=== 通った: $PKG on $OS ===" ||
	echo "=== 見込みと違った: $PKG on $OS ==="
exit $rc
