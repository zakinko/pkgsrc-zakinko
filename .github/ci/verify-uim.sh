#!/bin/sh
# inputmethod/uim の PLIST が option を切ったときに合わないのを、実機で
# 再現してから直して見せる。
#
#   sh verify-uim.sh <カテゴリ>/<パッケージ>
#
# build-on-bsd.sh が TREE_PKGS から名前で引いて呼ぶ。zakinko/ には
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

# gtk2 だけを切る。報告されたのがその形である。
#
# 一度は toolkit も xim も全部切る形にしていた。依存を軽くするためだったが、
# xim を切ると別のバグを踏む。
#
#	ERROR: [subst.mk:xim] The filename pattern "configure" has no effect.
#
# options.mk は xim を切ると configure に SUBST を掛ける作りだが、uim は
# Makefile.common の pre-configure が autogen.sh を走らせて configure を
# 生成する。SUBST の時点ではまだ無い。pkgsrc の subst.mk は効かない
# パターンを今はエラーにするので、そこで止まる。#153 とは別の、同じ
# options.mk の二つ目のバグである。踏むと #153 の再現にならない。
#
# gtk3 も落とす。残すと三つ目の壁を踏む。
#
#	ERROR: wayland>=1.21.0 is not installed; can't buildlink files.
#
# gtk3+ 自体はバイナリで降りてくる (39 回の bin-install の中に在る) が、
# gtk3 の buildlink3.mk が要求する wayland は uim の依存一覧に現れないので、
# 降ろす対象にならない。bin-install は package とその実行時依存しか入れず、
# buildlink だけが要求するものまでは面倒を見ない。
#
# xim は残す。切ると subst.mk のバグを踏む。
#
# gtk2 と gtk3 を両方落としても #153 の再現にはなる。重複 18 行が全部
# 「組まれていないのに PLIST が主張するもの」になるためで、むしろ一度に
# 全部出る。
OPTS=${UIM_OPTIONS:-"-gtk2 -gtk3 -gtk4 -qt5 -qt6"}

PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
PATH=$PATH:/usr/X11R7/bin:/usr/X11R6/bin
export PATH

# 依存は公式のバイナリパッケージから引く。
#
# uim は toolkit を全部切っても librsvg-c -> cairo -> fontconfig -> glib2 に
# ruby と anthy が乗る。素から一回で組もうとして 5 時間 30 分かけ、GitHub の
# 1 job 6 時間の上限で切られた。伸ばす余地はほぼ無い。
#
# 公式の四半期集合には uim-1.9.7pre20251027nb5 が、つまりこちらが見たいのと
# 同じ版がそのまま在る。ツリーを同じ四半期枝に合わせておけば、依存は
# DEPENDS_TARGET=bin-install で降ってきて、組むのは uim だけになる。
# PLIST の重複は 2025-11-15 の rev 1.29 からのものなので、四半期枝でも
# current でも同じように在る。
#
# 出どころは BINPKG_SITES で渡す。PKG_PATH ではない。あれを設定したまま
# pkgsrc の make を走らせると
#
#	ERROR: [bsd.pkg.mk] Please unset PKG_PATH before doing pkgsrc work!
#
# で組む前に弾かれる。最初それで転けた。
# 座標は arch と release の二つで決まる。どちらもゲストの中で引く。
#
#   arch     uname -p が amd64 で x86_64、i386 で i386 を返す。ミラーの
#            正準は x86_64 で、amd64/ はそこへの redirect である。
#   release  集合は枝の頭にしか無い。9.4 も 10.1 も点リリースの側は
#            redirect で、しかも arch ごとに飛び先の四半期が違う。
#
#              i386/9.4    -> i386/9.0_2026Q1
#              x86_64/9.4  -> x86_64/9.0_2026Q2
#
#            redirect に任せると arch で別の四半期を引くので、major に
#            .0 を付けた枝の頭を自分で組み立てる。
#
# 四半期のほうは固定にする。ツリーを四半期枝で取っているとき版が噛み合う
# ので、そこを動かすと噛み合わなくなる。
#
# 末尾に /All を付けないこと。mk/install/bin-install.mk が自分で足すので、
# 付けると .../All/All を引きに行き、見つからなければ黙ってソースビルドへ
# 落ちる。失敗としては出ない。
if [ "$OS" = NetBSD ] && [ -z "${BINPKG_SITES:-}" ]; then
	_rel=$(uname -r); _br=${_rel%%.*}.0
	BINPKG_SITES=http://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/$(uname -p)/${_br}_2026Q2
fi
unset PKG_PATH
echo "--- 依存の出どころ: $BINPKG_SITES ---"

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

# uim は graphics/librsvg/tool.mk を読む。既定の librsvg は Rust 実装で、
# rust 1.92 と cargo-c を引く。PLIST を一つ見るのにその山を積む意味がない。
# available.mk が LIBRSVG_TYPE を user-settable と明記していて、c にすると
# graphics/librsvg-c の方を使う。mk.conf ではなくコマンドラインで渡すのは、
# pkgsrc の優先順位が 環境変数 < mk.conf < コマンドライン だからで、
# build-on-bsd.sh が書く mk.conf は mule と共有しているため触りたくない。
MKARGS="$MKARGS LIBRSVG_TYPE=c"
MKARGS="$MKARGS DEPENDS_TARGET=bin-install BINPKG_SITES=$BINPKG_SITES"

# X11_TYPE は既定 (native) のまま。netbsd-ci-images のイメージは xbase も
# xserver も入れてあるので /usr/X11R7 がある。
#
# vmactions の netbsd-vm では X のセットが無く、配布セットを足した上で
# X11_TYPE=native にすると fonts/fontconfig が .x11-buildlink を触りに
# いって落ちた。modular に逃がすと今度は 4 時間で 8 パッケージしか組めず
# timeout に当たった。あちらは KVM が効かず TCG になるためで、こちらの
# イメージなら KVM で動く。

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

# 出力を握り潰さない。ここは 5 時間を超えることがあり、握り潰すと途中が
# 一切見えないまま timeout で切られて、何が起きていたかも残らない。実際に
# 一度そうなった。tee で流しつつ log にも残す。$? はパイプの右端のものに
# なるので、左の状態を別に取る。
{ $PKGMAKE $MKARGS PKG_OPTIONS.uim="$OPTS" install 2>&1; echo $? > /tmp/uim-rc; } |
	tee /tmp/uim-plain.log
if [ "$(cat /tmp/uim-rc)" -eq 0 ]; then
	echo 'RESULT 素のまま: 通った'
	echo '!! 読みが外れている。PLIST が合わないのに入るなら、'
	echo '!! この箱では PR #153 の問題は起きていないことになる。'
	rc=1
else
	# 落ちただけでは足りない。PLIST の食い違いで落ちたのか、依存や
	# platform の都合で configure まで届かなかったのかを見分ける。
	# 前は「落ちた = #153 のとおり」と書いていて、X11 が無くて
	# can-be-built-here.mk で弾かれたのを再現と読み違えた。
	if grep -qE 'but not installed|Files or directories in PLIST|pkg_create.*(stat|No such file)' \
	   /tmp/uim-plain.log; then
		echo 'RESULT 素のまま: PLIST の食い違いで落ちた (PR #153 が言うとおり)'
	elif grep -q 'PKG_FAIL_REASON' /tmp/uim-plain.log; then
		echo 'RESULT 素のまま: 組む前に弾かれた (#153 の再現になっていない)'
		grep -nE 'ERROR:' /tmp/uim-plain.log | head -10
		rc=1
	else
		echo 'RESULT 素のまま: 別の理由で落ちた (#153 の再現になっていない)'
		rc=1
	fi
fi
echo '--- PLIST の食い違いに触れている行 ---'
grep -nE 'but not installed|Files or directories in PLIST|pkg_create' \
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
{ $PKGMAKE $MKARGS PKG_OPTIONS.uim="$OPTS" install 2>&1; echo $? > /tmp/uim-rc; } |
	tee /tmp/uim-fixed.log
if [ "$(cat /tmp/uim-rc)" -eq 0 ]; then
	echo 'RESULT 直したあと: 通った'
else
	echo 'RESULT 直したあと: 落ちた'
	tail -40 /tmp/uim-fixed.log
	rc=1
fi

# ------------------------------------------------------------------
echo
echo "########## 3.5 動くか ##########"
# 建って PLIST が合っても、動かなければ「直った」とは言えない。uim は
# 変換エンジンなので、載せ替えた PLIST が実体と食い違っていれば plugin が
# 見つからない形で出る。
if [ -x "$PREFIX/bin/uim-module-manager" ]; then
	echo "--- 入っている module ---"
	"$PREFIX/bin/uim-module-manager" --path "$PREFIX/share/uim" --list 2>&1 |
		head -8
	echo "  exit=$?"
else
	echo "!! uim-module-manager が無い"; rc=1
fi
if [ -x "$PREFIX/bin/uim-sh" ]; then
	# uim-sh は Scheme を食う。uim 自身が初期化できるかを見るのに使う。
	echo "--- uim-sh に式を食わせる ---"
	echo '(display (uim-version))' | "$PREFIX/bin/uim-sh" 2>&1 | head -3
	echo "  exit=$?"
else
	echo "!! uim-sh が無い"; rc=1
fi

# ------------------------------------------------------------------
echo
echo "########## 4. 入ったものが本当に置かれているか ##########"
# option を入れた側では、消した 18 行が PLIST_SRC で戻っているかも見る。
# 消しすぎていれば「置かれているのに PLIST に無い」として出る。pkg_add は
# 並んでいないものを入れないので、そこは pkg_info では見えない。入った
# はずのファイルを名指しで確かめる。
case "$OPTS" in
*-gtk2*)	;;   # 切っている側は対象外
*gtk2*)
	echo "--- gtk2 を入れているので、戻った行が実在するかを見る ---"
	miss2=0
	for f in $(grep -v '^@comment' PLIST.gtk2); do
		[ -e "$PREFIX/$f" ] || { echo "    無い: $PREFIX/$f"; miss2=$((miss2 + 1)); }
	done
	if [ $miss2 -eq 0 ]; then
		echo "PLIST.gtk2 の 9 行は全部置かれている (PLIST_SRC が足し直している)"
	else
		echo "FAIL: $miss2 個が置かれていない。消しすぎている。"
		rc=1
	fi
	;;
esac
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
