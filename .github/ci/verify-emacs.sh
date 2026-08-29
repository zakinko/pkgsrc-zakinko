#!/bin/sh
# zakinko/emacs22 から emacs28 を、その箱で確かめる。
#
#   sh verify-emacs.sh "zakinko/emacs28-nox11 zakinko/emacs28 zakinko/emacs ..."
#
# 先頭が組む対象で、残りは run-in-qemu.sh が一緒に運んでくる連れ。
# emacs28-nox11 は emacs28 の Makefile.common と PLIST を読み、さらに
# zakinko/emacs/modules.mk を読むので、三つ揃わないと建たない。
#
# 上流 pkgsrc は 2026-08-25 に emacs26/27/28 を、それ以前に emacs22 から
# emacs25 を消した。ここに引き取ったものはもう誰も見ていないので、CI が
# 唯一の見張りになる。見るのは四段階。
#
#   1. 組めて入る               PLIST と食い違わないか
#   2. 起きて、当て物が効いている
#                               版が名乗るとおりか、CVE の当て物が入れた
#                               名前が実際にあるか。当たっただけでは
#                               「その関数が居る」ことにならないので、
#                               走らせて確かめる
#   3. 日本語が変換できる       この版で elisp パッケージが建ち、実際に
#                               nihongo が 日本語 になるか。ここは
#                               verify-anthy-elisp.sh をそのまま呼ぶ。
#                               同じものを二つ書くと片方が古くなる
#   4. 外せる
#
# EMACS_COEXIST_CHECK=yes を渡すと、共存の形でも組み直して bin/emacs28 が
# でき bin/emacs ができないことまで見る。emacs をもう一度丸ごと建てるので
# 既定では走らせない。

set -e

SPEC=${1:-zakinko/emacs28-nox11}
PKGPATH=$(echo "$SPEC" | awk '{print $1}')
PKG=$(basename "$PKGPATH")

# emacs28-nox11 -> 28 / emacs28nox、emacs28 -> 28 / emacs28
V=$(echo "$PKG" | sed 's/^emacs\([0-9][0-9]*\).*/\1/')
case $PKG in
*-nox11)	EMACS_TYPE=emacs${V}nox ;;
*)		EMACS_TYPE=emacs${V} ;;
esac

OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
HERE=$(cd "$(dirname "$0")" && pwd)

PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
PATH=$PATH:/usr/X11R7/bin:/usr/X11R6/bin:/usr/local/bin
export PATH
unset PKG_PATH

if [ "$OS" = NetBSD ]; then
	# BATCH=1 と、stdin を閉じること。当て物が当たらないと patch は
	#
	#	File to patch:
	#	No file found--skip this patch? [n]
	#
	# と聞き、pkgsrc は stdin を閉じないので永久に聞き続ける。job は無音のまま
	# 340 分の timeout に当たり、何が起きたのか一行も残らなかった (手元で同じ
	# ものを回したらログが 6087 万行になった)。BATCH=1 は pkgsrc が patch へ
	# --batch を渡すようにする。
	BATCH=1; export BATCH
	PKGMAKE=make
	MKARGS=
else
	PKGMAKE=$PREFIX/bin/bmake
	MKARGS="DEPENDS_TARGET=package-install"
fi
# 依存は在ればバイナリで引く。emacs は依存が深いので、素から組むと job の
# 上限 360 分に近づく。
#
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
	MKARGS="$MKARGS DEPENDS_TARGET=bin-install BINPKG_SITES=$BINPKG_SITES"
	echo "    依存の出どころ: $BINPKG_SITES"
else
	echo "    依存の出どころ: 無し。全部その場で組む"
fi

DIR=$TREE/$PKGPATH
echo "--- $PKGPATH ($OS $(uname -r) / $(uname -m) / EMACS_TYPE=$EMACS_TYPE) ---"
cd "$DIR" || { echo "FAIL: $DIR が無い"; exit 1; }

# 当て物の SHA1 が distinfo に入っているか。makepatchsum を回し忘れると
# ここから先が全部そのせいになるので先に見る。
D=$TREE/zakinko/emacs$V
for p in "$D/patches"/patch-*; do
	[ -e "$p" ] || continue
	b=${p##*/}
	grep -q "SHA1 ($b)" "$D/distinfo" || {
		echo "FAIL: distinfo に $b の SHA1 が無い"; exit 1; }
done
echo "    当て物 $(ls "$D/patches" 2>/dev/null | wc -l | tr -d ' ') 本"

pkg_delete -f "$PKG" > /dev/null 2>&1 || true

# 前に別の PKGREVISION で組んだ package が残っていると、pkgsrc は名前が
# 違ってもそちらを入れることがある。VM は使い捨てなので普段は空振りだが、
# 手元で回すときに効く。
$PKGMAKE $MKARGS clean > /dev/null 2>&1 || true

echo "--- 1. build と install ---"
if ! $PKGMAKE $MKARGS package-install < /dev/null > /tmp/verify-$PKG.log 2>&1; then
	grep -iE 'hunks? failed|saving rejects|Patching failed|in the PLIST but not|not in the PLIST' \
	    /tmp/verify-$PKG.log | head -10
	tail -40 /tmp/verify-$PKG.log
	echo "FAIL: $PKGPATH が入らない"
	exit 1
fi
tail -2 /tmp/verify-$PKG.log

# 依存をバイナリで降ろせたのか、その場で組んだのかを出す。build のログは
# 上のリダイレクトに入って外から見えないので、ここで数えて出さないと
# 「緑になった」以上のことが分からない。i386 のイメージへ x86_64 の
# BINPKG_SITES を渡していたときは一つも降ろせず素から組んでいて、amd64 の
# 倍近い時間がかかっていたが、ログからは気づけなかった。
_bin=$(grep -c "Installing binary package of" /tmp/verify-$PKG.log 2>/dev/null || true)
_src=$(grep -c "^===> Building for" /tmp/verify-$PKG.log 2>/dev/null || true)
echo "    依存: バイナリ ${_bin:-0} 件 / その場で組んだの ${_src:-0} 件"
if [ -n "${BINPKG_SITES:-}" ] && [ "${_bin:-0}" = 0 ]; then
	echo "    ::warning:: BINPKG_SITES を渡したのに一つも降ろせていない"
fi

VER=$($PKGMAKE show-var VARNAME=EMACS_VERSION)
echo "--- 2. 起きて、当て物が効いているか (期待 $VER) ---"
E=$PREFIX/bin/emacs
[ -x "$E" ] || { echo "FAIL: $E が無い"; exit 1; }
"$E" --version | head -1 | sed 's/^/    /'
# Emacs 25 までは三つ目の桁を付けて名乗る。22.3 は "GNU Emacs 22.3.1"、
# 25.3 は "GNU Emacs 25.3.1" で、EMACS_VERSION は二桁の 22.3 と 25.3。
# 26 で付かなくなったので、26 から 28 だけが末尾一致で通っていた。
# 三つ目を任意にする。
"$E" --version | head -1 | grep -qE " $VER(\.[0-9]+)?\$" || {
	echo "FAIL: 名乗る版が $VER ではない"; exit 1; }
[ -x "$PREFIX/bin/emacs-$VER" ] || {
	echo "FAIL: bin/emacs-$VER が無い"; exit 1; }

# 当て物が入れた名前が実際に居るか。当たったことと居ることは別。
"$E" -Q --batch --eval '
(let ((bad nil))
  (dolist (f (list (quote trusted-content-p)
                   (quote elisp--safe-macroexpand-all)
                   (quote org--should-fetch-remote-resource-p)
                   (quote org--confirm-resource-safe)))
    (require (quote elisp-mode) nil t)
    (require (quote org) nil t)
    (unless (fboundp f) (push f bad)))
  (dolist (v (list (quote untrusted-content)
                   (quote org-resource-download-policy)
                   (quote org-safe-remote-resources)))
    (unless (boundp v) (push v bad)))
  (if bad
      (progn (princ (format "MISSING %S\n" (nreverse bad))) (kill-emacs 1))
    (princ "SECURITY-NAMES-OK\n")))' 2>&1 | sed 's/^/    /'

echo "--- 3. 日本語が変換できるか ---"
EMACS_TYPE=$EMACS_TYPE sh "$HERE/verify-anthy-elisp.sh" zakinko/anthy-elisp || {
	echo "FAIL: $EMACS_TYPE で変換できない"; exit 1; }

# mozc は見ない。zakinko/mozc-elisp の do-build は bazel で
# mozc_emacs_helper (C++) を建てるので、依存をバイナリで降ろしても
# パッケージ自身に数時間かかり、job の上限 360 分に当たる。
# emacs 側が壊れているかどうかは anthy 側で十分に踏める。mozc を見るなら
# 別の workflow で、押したときだけ回すのが筋になる。

if [ "${EMACS_COEXIST_CHECK:-no}" = yes ]; then
	echo "--- 3b. 共存の形でも組めるか ---"
	pkg_delete -f "$PKG" > /dev/null 2>&1 || true
	$PKGMAKE clean > /dev/null 2>&1 || true
	if ! $PKGMAKE $MKARGS EMACS_COEXIST=yes package-install < /dev/null \
	     > /tmp/verify-$PKG-coexist.log 2>&1; then
		# 30 行では足りなかった。coexist-names の mv が
		# "rename emacs.1 to emacsNN.1: No such file or directory" で
		# 落ちたとき、man を入れる段がその手前に見えず、どこで消えたのか
		# 分からなかった。install の並びが見える程度まで出す。
		tail -120 /tmp/verify-$PKG-coexist.log
		echo "--- destdir に何が入っているか ---"
		D=$($PKGMAKE $MKARGS EMACS_COEXIST=yes show-var VARNAME=DESTDIR 2>/dev/null)
		W=$($PKGMAKE $MKARGS EMACS_COEXIST=yes show-var VARNAME=WRKDIR 2>/dev/null)
		for d in "$D$PREFIX/bin" "$D$PREFIX/man/man1" "$W/.destdir$PREFIX/bin" \
		         "$W/.destdir$PREFIX/man/man1" "$W/.destdir$PREFIX/share/man/man1"; do
			[ -d "$d" ] || continue
			echo "    $d:"
			ls "$d" 2>/dev/null | sed 's/^/      /'
		done
		echo "FAIL: EMACS_COEXIST=yes で入らない"; exit 1
	fi
	[ -x "$PREFIX/bin/emacs$V" ] || {
		echo "FAIL: bin/emacs$V が無い"; exit 1; }
	[ ! -e "$PREFIX/bin/emacs" ] || {
		echo "FAIL: 共存の形なのに bin/emacs が入っている"; exit 1; }
	[ -f "$PREFIX/info/emacs$V/emacs.info.gz" ] || {
		echo "FAIL: info が info/emacs$V/ に入っていない"; exit 1; }
	echo "    bin/emacs$V あり、bin/emacs 無し、info/emacs$V/ あり"
fi

echo "--- 4. 外せるか ---"
$PKGMAKE deinstall > /dev/null 2>&1 || pkg_delete "$PKG" > /dev/null 2>&1 || {
	echo "FAIL: $PKG が外せない"; exit 1; }

echo "=== 通った: $PKGPATH on $OS ($EMACS_TYPE で変換できた) ==="
