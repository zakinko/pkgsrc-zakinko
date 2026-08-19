#!/bin/sh
# zakinko/anthy と anthy-elisp の当て物を、その箱で確かめる。
#
#   sh verify-anthy-elisp.sh [zakinko/anthy-elisp]
#
# 素の pkgsrc で落ちることを見るときは inputmethod/anthy-elisp を渡す。
# anthy 側の patch は引数と同じカテゴリから引くので、どちらでも筋が通る。
#
# verify-pkg.sh では足りない。あちらは「組めて、入って、PLIST どおりに
# 置かれて、外せる」を見るが、この当て物が相手にしている壊れかたは
# そこを素通りする。
#
# anthy.el は Emacs 30 で消えた process-kill-without-query を
# anthy-check-agent の中で呼ぶ。関数の中なので byte-compile は「知らない
# 関数」の警告で済ませ、.elc は 6 本そろい PLIST とも食い違わない。
# つまり verify-pkg.sh は緑を返す。それでいて入力方式は最初の変換要求で
# void-function に落ちる。
#
# なので三段階で見る。
#
#   1. 組んで入る                     ここは verify-pkg.sh と同じ
#   2. .elc が 6 本そろう             set-face-underline-p (Emacs 29 で削除)
#                                     が残っていると 4 本しかできない
#   3. 実際に日本語が変換できる       ここが本題。emacs を起こして
#                                     nihongo を打ち、変換して確定し、
#                                     書き出した先に 日本語 があるか
#
# 3 が要る理由は上のとおりで、2 まで緑でも 3 で落ちる状態が実在する。
#
# EMACS_TYPE はコマンドラインで渡す。mk.conf に書いても環境変数には勝つが、
# こちらは逆に mk.conf に勝ちたい。pkgsrc は環境変数 < mk.conf < コマンド
# ラインの順なので、確実なのはコマンドライン。

PKGPATH=${1:-zakinko/anthy-elisp}
PKG=$(basename "$PKGPATH")
ANTHY=$(dirname "$PKGPATH")/anthy

OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
EMACS_TYPE=${EMACS_TYPE:-emacs30nox}

PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
PATH=$PATH:/usr/X11R7/bin:/usr/X11R6/bin:/usr/local/bin
export PATH
unset PKG_PATH

if [ "$OS" = NetBSD ]; then
	PKGMAKE=make
	MKARGS=
else
	PKGMAKE=$PREFIX/bin/bmake
	MKARGS="DEPENDS_TARGET=package-install"
fi
MKARGS="$MKARGS EMACS_TYPE=$EMACS_TYPE"

DIR=$TREE/$PKGPATH

echo "--- $PKGPATH ($OS $(uname -r) / $(uname -m) / EMACS_TYPE=$EMACS_TYPE) ---"
cd "$DIR" || { echo "FAIL: $DIR が無い"; exit 1; }

# 当て物の SHA1 が distinfo に入っているか。build-on-bsd.sh が
# makepatchsum を回しているが、digest が無くて黙って失敗していると
# ここから先が全部そのせいになるので、先に見る。
for p in "$TREE/$ANTHY/patches"/patch-*; do
	[ -e "$p" ] || continue
	b=${p##*/}
	grep -q "SHA1 ($b)" "$TREE/$ANTHY/distinfo" || {
		echo "FAIL: distinfo に $b の SHA1 が無い"; exit 1; }
done
grep 'SHA1 (patch-' "$TREE/$ANTHY/distinfo" | sed 's/^/    /'

pkg_delete -f "$PKG" > /dev/null 2>&1 || true

echo "--- 1. build と install ---"
# emacs を依存で引くので長い。
if ! $PKGMAKE $MKARGS install > /tmp/verify-$PKG.log 2>&1; then
	if grep -qi 'not available for this platform' /tmp/verify-$PKG.log; then
		echo "SKIP: $PKGPATH は $OS を相手にしていない (ONLY_FOR_PLATFORM)"
		exit 0
	fi
	# 当て物が当たらなかったのか、その先で転けたのかを一行で分ける。
	grep -iE 'hunks failed|saving rejects|Patching failed|in the PLIST but not' \
	    /tmp/verify-$PKG.log | head -10
	tail -30 /tmp/verify-$PKG.log
	echo "FAIL: $PKGPATH が入らない"
	exit 1
fi
tail -3 /tmp/verify-$PKG.log

LISP=$($PKGMAKE $MKARGS show-var VARNAME=EMACS_LISPPREFIX)/anthy
EMACS=$($PKGMAKE $MKARGS show-var VARNAME=EMACS_BIN)

echo "--- 2. .elc は 6 本そろったか ---"
ls "$LISP" | sed 's/^/    /'
n=$(ls "$LISP"/*.elc 2>/dev/null | wc -l | tr -d ' ')
echo "    .elc: $n/6"
[ "$n" -eq 6 ] || {
	echo "FAIL: .elc が足りない。set-face-underline-p が残っていないか"
	exit 1; }

echo "--- 3. 実際に変換できるか ---"
[ -x "$EMACS" ] || { echo "FAIL: $EMACS が無い"; exit 1; }
command -v anthy-agent > /dev/null 2>&1 || {
	echo "FAIL: anthy-agent が PATH に無い"; exit 1; }

# anthy.el は anthy-agent-command-list の既定どおり PATH から agent を引く。
cat > /tmp/anthy-smoke.el <<'ELISP'
(set-language-environment "Japanese")
(prefer-coding-system 'utf-8)
(load-library "anthy")
(set-buffer (get-buffer-create "*smoke*"))
;; with-temp-buffer は undo を無効にする (buffer-undo-list が t)。
;; anthy-update-preedit がそれを list として辿るので、実バッファで打つ。
(buffer-enable-undo)
(anthy-mode-on)
(dolist (c (string-to-list "nihongo"))
  (setq last-command-event c)
  (anthy-insert))
(setq last-command-event ?\s)			; 変換
(anthy-insert)
(setq last-command-event ?\C-m)			; 確定
(anthy-insert)
(let ((coding-system-for-write 'utf-8))
  (write-region (point-min) (point-max) "/tmp/anthy-smoke.out"))
ELISP

# -Q は site-lisp を load-path から外すので明示的に足す。
rm -f /tmp/anthy-smoke.out
"$EMACS" -Q --batch --eval "(add-to-list 'load-path \"$LISP\")" \
    -l /tmp/anthy-smoke.el > /tmp/anthy-smoke.log 2>&1
sed -n '1,15p' /tmp/anthy-smoke.log | sed 's/^/    /'

if [ ! -f /tmp/anthy-smoke.out ]; then
	echo "FAIL: emacs が書き出す前に落ちた"
	exit 1
fi
echo "    書き出したもの: $(cat /tmp/anthy-smoke.out)"
LC_ALL=C grep -q '日本語' /tmp/anthy-smoke.out || {
	echo "FAIL: nihongo が 日本語 にならない"
	exit 1; }

echo "--- 外せるか ---"
$PKGMAKE $MKARGS deinstall > /dev/null 2>&1 || pkg_delete "$PKG" > /dev/null 2>&1 || {
	echo "FAIL: $PKG が外せない"; exit 1; }

echo "=== 通った: $PKGPATH on $OS ($EMACS_TYPE で変換できた) ==="
