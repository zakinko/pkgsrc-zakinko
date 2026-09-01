#!/bin/sh
# xwpe の当て物 3 本が今も要ることを、当てる前後を建て分けて見る。
#
#   sh verify-xwpe.sh <カテゴリ>/<パッケージ>
#
# 何を見ているか
# --------------
# GitHub の NetBSD/pkgsrc PR #180 は editors/xwpe を 1.6.6 へ上げるもの。
# 出したのは Debian のメンテナで、かつ xwpe の現上流でもある。今の上流は
# 1.6.9 まで進んでいる。
#
# 1.5.30a 向けの当て物 9 本のうち 6 本は要らなくなった。patch-aa が直して
# いた DESTDIR の壊れ (手書き Makefile.in が DESTDIR を bindir の意味で
# 使っていた) は、1.6.x が autotools へ移ったので消えている。他の 5 本は
# 上流が取り込んだ。
#
# 残す 3 本は、どれもコンパイラの診断だった。
#
#   patch-WeXterm.c      e_X_sw_color の暗黙の宣言
#   patch-we__xterm.c    WpeMouseRestoreShape への不正なキャスト
#   patch-we__wayland.c  同上 (1.6.6 で入った Wayland 側)
#
# Debian は 1.6.6-1 で当て物をゼロにしている (debian/patches/series が空)。
# 同じ人が上流とメンテナを兼ねているので、要らないから消したように見える。
# こちらは「Debian は gcc 既定で組むから通るだけで、clang では error に
# なる」と読んで 3 本を残していた。
#
# 測ったら外れていた。1.6.9 の Makefile.am:41 が自分で覆っている。
#
#   -Wno-incompatible-pointer-types
#   -Wno-implicit-function-declaration
#   -Wno-int-conversion
#   -Wno-old-style-declaration
#
# 当て物が直していた診断がそのままここに並んでいる。NetBSD 11.0 の
# gcc 12.5.0 でも、pkgsrc の clang 21.1.8 でも、3 本を外して通った。
# clang で走ったことは -Wno-old-style-declaration を知らないという
# unknown-warning-option が 33 回出たことで分かる。gcc はそれを知っている。
#
# だから 3 本は落とした。落としたので、この検査が見るのは「外しても通る」
# ではなく「もう当て物はこれだけで足りているか」になる。残っているのは
#
#   patch-we__render.h   X11 だけで Cairo が無いと link が通らない
#
# の一本で、これは上流のバグである。#ifdef NO_XWINDOWS で空実装を選ぶが、
# 本体を持つ we_render_cairo.c は #ifdef HAVE_CAIRO の中にしか無い。
#
# 見るのは三つ。
#
#   1. 当て物ありで建てる    -> 通るはず
#   2. 建った実体を動かす    -> 起動して終われるか
#   3. 当て物を外して建て直す -> clang の箱では落ちるはず。gcc の箱では
#                               通るかもしれない。どちらだったかを記録する
#
# 3 が箱によって割れるのが、この検査の見どころである。割れ方そのものが
# 「なぜ Debian は要らず pkgsrc は要るのか」の答えになる。

# 呼ばれ方が二通りある。
#
#   run-in-qemu.sh   UPSTREAM_PKG をそのまま第一引数で渡す (zakinko/xwpe)
#   build-on-bsd.sh  PKGS 経由だと第一引数は PKG_OPTIONS.mule である
#                    (verify-mule.sh がそれを受ける規約のため)
#
# 後者をパッケージ名と読んで /usr/pkgsrc/-canna -wnn4 -x11 を探しに行った。
# ツリーに在る名前だったときだけ受け取り、そうでなければ既定に落とす。
PKG=zakinko/xwpe
if [ -n "${1:-}" ] && [ -d "${TREE:-/usr/pkgsrc}/$1" ]; then
	PKG=$1
fi

OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}

PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
PATH=$PATH:/usr/X11R7/bin:/usr/X11R6/bin
export PATH
unset PKG_PATH

if [ -x "$PREFIX/bin/bmake" ]; then
	PKGMAKE=$PREFIX/bin/bmake
	MKARGS="DEPENDS_TARGET=bin-install"
	# BINPKG_SITES は呼ぶ側が環境に置く。それでも効いてはいて、NetBSD
	# amd64-11.0 の run 32790708281 ではバイナリ 49 件、その場で組んだの
	# 47 件だった。ただし pkgsrc の変数の強さは 環境 < mk.conf < コマンド
	# ラインなので、mk.conf に BINPKG_SITES があると環境のほうが負ける。
	# 明示して渡す。
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
	if [ -n "${BINPKG_SITES:-}" ]; then
		MKARGS="$MKARGS BINPKG_SITES=$BINPKG_SITES"
		echo "--- 依存の出どころ: $BINPKG_SITES ---"
	else
		echo "--- 依存の出どころ: 無し。全部その場で組む ---"
	fi
elif [ "$OS" = NetBSD ]; then
	# NetBSD には base の make が在るので bootstrap しない箱がある。
	# ここで MKARGS を空にしていたため、bmake の無い NetBSD では依存を
	# 一つも降ろさず全部その場で組んでいた。落ちずに遅くなるだけなので、
	# 4 時間の timeout に当たるまで理由が分からない。上の枝と同じものを
	# 渡す。
	PKGMAKE=make
	MKARGS="DEPENDS_TARGET=bin-install"
	if [ -z "${BINPKG_SITES:-}" ]; then
		_rel=$(uname -r); _br=${_rel%%.*}.0
		BINPKG_SITES=http://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/$(uname -p)/${_br}_2026Q2
	fi
	MKARGS="$MKARGS BINPKG_SITES=$BINPKG_SITES"
	echo "--- 依存の出どころ: $BINPKG_SITES ---"
else
	echo "FAIL: $PREFIX/bin/bmake が無い"; exit 1
fi

PKGBASE=${PKG##*/}
DIR=$TREE/$PKG
cd "$DIR" || { echo "FAIL: $DIR が無い"; exit 1; }

rc=0
echo "--- $PKG ($OS $(uname -r) / $(uname -m)) ---"
# base の cc を出しても意味が無い。pkgsrc は cwrappers を噛ませるので、
# PKGSRC_COMPILER で選んだものが実際に走る。clang で組んだ回に
# 「cc 12.5.0」と表示していて、記録としては嘘だった。
echo "--- コンパイラ ---"
echo "  PKGSRC_COMPILER = ${PKGSRC_COMPILER:-(既定)}"
case ${PKGSRC_COMPILER:-} in
clang)	${PREFIX}/bin/clang --version 2>/dev/null | head -1 ;;
*)	${CC:-cc} --version 2>/dev/null | head -1 ;;
esac

# ------------------------------------------------------------------
echo
echo "########## 1. 当て物ありで建てる ##########"
ls patches 2>/dev/null
pkg_delete -f "$PKGBASE" > /dev/null 2>&1 || true
{ $PKGMAKE $MKARGS install 2>&1; echo $? > /tmp/xwpe-rc; } | tee /tmp/xwpe-patched.log
_bin=$(grep -c "===> Binary install for" /tmp/xwpe-patched.log 2>/dev/null || true)
_src=$(grep -c "^===> Building for" /tmp/xwpe-patched.log 2>/dev/null || true)
echo "--- 依存: バイナリ ${_bin:-0} 件 / その場で組んだの ${_src:-0} 件 ---"
if [ -n "${BINPKG_SITES:-}" ] && [ "${_bin:-0}" = 0 ]; then
	echo "::warning::BINPKG_SITES を渡したのに一つも降ろせていない"
fi
if [ "$(cat /tmp/xwpe-rc)" -eq 0 ]; then
	echo 'RESULT 当て物あり: 通った'
else
	echo 'RESULT 当て物あり: 落ちた'
	tail -40 /tmp/xwpe-patched.log
	rc=1
fi

# ------------------------------------------------------------------
echo
echo "########## 2. 建った実体を動かす ##########"
# 組めたことと動くことは別である。全画面 editor なので端末が要る。
# script(1) は NetBSD では -c を付けても転写が空だったので、openpty(3) を
# 直に叩く駆動器を組んで、その向こうで本当に file を開いて書いて保存する。
#
# 画面から escape を落としてから探すこと。強調は E<esc>[0;1;7mdit のように
# 語の途中へ入るので、生のまま grep すると menu が「無い」と出る。
_strip() {
	LC_ALL=C sed -e 's/\x1b\[[0-9;?]*[a-zA-Z]//g' -e 's/\x1b[()][A-Z0-9]//g' \
		-e 's/\x1b\][0-9;]*[a-zA-Z]*//g' -e 's/\x1b[=>]//g' -e 's/\x1b//g' "$1" |
	LC_ALL=C tr -d '\000-\010\013\014\016-\037'
}
_hex() { printf '%s' "$1" | od -An -tx1 | tr -d ' \n'; }

if [ -x "$PREFIX/bin/we" ]; then
	echo "--- 名乗るか ---"
	"$PREFIX/bin/we" --version < /dev/null 2>&1 | head -2
	echo "  --version の終了状態: $?"
	"$PREFIX/bin/we" --help < /dev/null 2>&1 | head -3

	echo "--- 繋がっている library ---"
	if ldd "$PREFIX/bin/we" 2>/dev/null | grep -q 'not found'; then
		echo "  !! 解決していないものが在る"
		ldd "$PREFIX/bin/we" | grep 'not found'; rc=1
	else
		echo "  ok すべて解決 ($(ldd "$PREFIX/bin/we" 2>/dev/null | grep -c '=>') 本)"
	fi
	# Xft を引いているのは上流のバグを避けるためなので、本当に繋がって
	# いることを見る。Makefile から .include を落としても素通りしない。
	ldd "$PREFIX/bin/we" 2>/dev/null | grep -q libXft &&
		echo "  ok libXft が繋がっている" ||
		{ echo "  !! libXft が繋がっていない"; rc=1; }

	echo "--- bin の四つ ---"
	for b in we wpe xwe xwpe; do
		printf '  %-6s ' "$b"
		ls -l "$PREFIX/bin/$b" 2>&1 | sed 's|.*/bin/||'
	done
	echo "--- 実行時に読むもの ---"
	for f in syntax_def help.xwpe help.key; do
		printf '  %-12s ' "$f"
		[ -s "$PREFIX/lib/xwpe/$f" ] && echo "あり ($(wc -c < "$PREFIX/lib/xwpe/$f") bytes)" ||
			{ echo "無い"; rc=1; }
	done

	echo "--- pty の向こうで開いて、書いて、保存して、終わる ---"
	_drv=$(dirname "$0")/ptydrive
	if [ ! -x "$_drv" ] && [ -f "$(dirname "$0")/ptydrive.c" ]; then
		cc -O2 -o "$_drv" "$(dirname "$0")/ptydrive.c" -lutil 2>/dev/null
	fi
	if [ -x "$_drv" ]; then
		cat > /tmp/xwpe-hello.c <<'CEOF'
#include <stdio.h>
int main(void) { printf("hello\n"); return 0; }
CEOF
		_before=$(cksum < /tmp/xwpe-hello.c)
		# 書く -> 改行 -> F2 で保存 -> Alt-X で終了 -> 聞かれたら Enter。
		# F2 の並びは端末から引く。決め打ちにすると TERM を変えた途端に
		# 「保存できていない」を「動かない」と読み違える。
		_f2=$(TERM=vt100 tput kf2 2>/dev/null | od -An -tx1 | tr -d ' \n')
		_keys="$(_hex '/* touched */')0d${_f2}1b780d"
		TERM=vt100 "$_drv" /tmp/xwpe-screen.raw 30 "$_keys" \
			"$PREFIX/bin/we" /tmp/xwpe-hello.c
		_rc=$?
		if [ $_rc -eq 9 ]; then
			echo "  !! 時限で降りた。editor が終わらなかった"; rc=1
		elif [ $_rc -ne 0 ]; then
			echo "  !! 駆動器が $_rc で降りた"; rc=1
		else
			echo "  ok Alt-X で終わった"
		fi
		echo "  画面 $(wc -c < /tmp/xwpe-screen.raw) bytes"
		_s=$(_strip /tmp/xwpe-screen.raw | tr -d '\n')
		for w in File Edit Search Block Options Window Help; do
			case $_s in
			*"$w"*)	printf '  ok   menu %s\n' "$w" ;;
			*)	printf '  !!   menu %s が出ていない\n' "$w"; rc=1 ;;
			esac
		done
		case $_s in
		*'xwpe-hello.c'*)	echo "  ok   title に file 名が出ている" ;;
		*)			echo "  !!   file 名が出ていない"; rc=1 ;;
		esac
		case $_s in
		*'stdio.h'*)	echo "  ok   file の中身が画面に出ている" ;;
		*)		echo "  !!   中身が出ていない"; rc=1 ;;
		esac
		_after=$(cksum < /tmp/xwpe-hello.c)
		echo "  file: $_before -> $_after"
		if grep -q 'touched' /tmp/xwpe-hello.c; then
			echo "  ok   打った文字が保存されている"
		else
			echo "  !!   保存されていない"; rc=1
		fi
	else
		echo "  !! 駆動器を組めなかった。動作は見ていない"; rc=1
	fi
else
	echo "!! $PREFIX/bin/we が無い"
	rc=1
fi

# ------------------------------------------------------------------
echo
echo "########## 3. 当て物を外して建て直す ##########"
# これが箱によって割れる。落ちれば「この箱には要る」、通れば「この箱には
# 要らない」。どちらも結果であって、失敗ではない。
mkdir -p /tmp/xwpe-patches && cp patches/* /tmp/xwpe-patches/ 2>/dev/null
cp distinfo /tmp/xwpe-distinfo.orig
$PKGMAKE clean > /dev/null 2>&1
pkg_delete -f "$PKGBASE" > /dev/null 2>&1 || true
rm -f patches/patch-we__render.h
sed -e '/patch-we__render.h/d' distinfo > distinfo.new && mv distinfo.new distinfo

{ $PKGMAKE $MKARGS build 2>&1; echo $? > /tmp/xwpe-rc; } | tee /tmp/xwpe-plain.log
if [ "$(cat /tmp/xwpe-rc)" -eq 0 ]; then
	echo "RESULT 当て物なし: 通った ($OS のこの箱では当て物は要らない)"
else
	echo "RESULT 当て物なし: 落ちた ($OS のこの箱では当て物が要る)"
fi
echo '--- 診断に出た行 ---'
grep -nE 'incompatible function pointer|undeclared function|implicit declaration' \
	/tmp/xwpe-plain.log | head -10

# 戻す
cp /tmp/xwpe-patches/* patches/ 2>/dev/null
cp /tmp/xwpe-distinfo.orig distinfo
$PKGMAKE clean > /dev/null 2>&1

[ $rc -eq 0 ] && echo "=== 通った: $PKG on $OS ===" ||
	echo "=== 見込みと違った: $PKG on $OS ==="
exit $rc
