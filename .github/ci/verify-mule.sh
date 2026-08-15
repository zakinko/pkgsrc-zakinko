#!/bin/sh
# NetBSD の中で走る。mule を組んで、実際に日本語が編集できるところまで確かめる。
#
#   $1  PKG_OPTIONS.mule に渡す文字列
#
# ビルドが通っただけでは通したことにしない。1995 年のこのコードは
# 「ビルドは通るのにダンプ済みバイナリが起動時に落ちる」「変換サーバに
# つながるのに辞書がひとつも登録されず読みがそのまま返る」という壊れ方を
# するので、ダンプ・起動・符号化の往復・編集操作・byte-compile・かな漢字
# 変換・X のフレームまで踏む。
#
# 判定は stderr を読まない。mule 2.3 は batch でエラーが起きると内容に
# 関わらず "INVALID DATATYPE" としか言わないので、メッセージから成否は
# 決められない。elisp に結果ファイルを書かせ、その中身と、書き出させた
# 符号化済みファイルのバイト列で判定する。
#
# 検査は最初の失敗で止めない。全部走らせて最後にまとめて落とす。1 回の
# 実行でどこまで壊れているかが分かるほうが、直す側の手数が少ない。

OPTS="$1"
PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/pkg/bin:/usr/pkg/sbin:/usr/X11R7/bin
export PATH
unset PKG_PATH

MULE=/usr/pkg/bin/mule
CI_DIR=/tmp/mule-ci
RES=$CI_DIR/results.txt
export CI_DIR
HERE=$(cd "$(dirname "$0")" && pwd)

ARCH=$(uname -m)
REL=$(uname -r | sed -e 's/_.*//')
echo "=== NetBSD ${REL} / ${ARCH} / PKG_OPTIONS.mule=\"${OPTS}\" ==="
gcc --version 2>/dev/null | head -1

fail=0
note() { echo "    $*"; }
bad()  { echo "    FAIL: $*"; fail=1; }
want() { case " $OPTS " in *" $1 "*) return 0 ;; esac; return 1; }

val()  { sed -n "s/^$1=//p" "$RES" 2>/dev/null | head -1; }
hexof() { od -An -tx1 "$1" 2>/dev/null | tr -d ' \n'; }

# 期待値と突き合わせる。値が無い場合と違う場合を区別して言う。
must() {
	_g=$(val "$1")
	if [ -z "$_g" ]; then bad "$1: 記録されていない (検査が走る前に落ちた)"
	elif [ "$_g" = "$2" ]; then note "$1 = $_g"
	else bad "$1: 期待 '$2' だが '$_g'"; fi
}
# 部分一致でよいもの
must_match() {
	_g=$(val "$1")
	case "$_g" in
	"")	bad "$1: 記録されていない" ;;
	*$2*)	note "$1 = $_g" ;;
	*)	bad "$1: '$2' を含むはずが '$_g'" ;;
	esac
}
info() { note "$1 = $(val "$1")  (参考値)"; }

must_bytes() {
	_g=$(hexof "$CI_DIR/$1")
	if [ -z "$_g" ]; then bad "$1: 書き出されていない"
	elif [ "$_g" = "$2" ]; then note "$1 のバイト列 OK"
	else bad "$1: 期待 $2 / 実際 $_g"; fi
}

# ------------------------------------------------------------------
echo "--- 依存をバイナリで入れる ---"
set -e
PKG_PATH="http://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/${ARCH}/${REL}/All/"
export PKG_PATH
for p in gmake gtexinfo mozilla-rootcerts; do pkg_add -U "$p" || true; done
want canna && { pkg_add -U Canna-lib Canna-server Canna-dict || true; }
want wnn4  && { pkg_add -U ja-FreeWnn-lib ja-FreeWnn-server || true; }
mozilla-rootcerts install > /dev/null 2>&1 || true
unset PKG_PATH

# x11-links はバイナリで入れない。symlink を張るだけの小さなパッケージで、
# 公式バイナリは pkgsrc current より古いことがある。古いほうが残っていると
# pkgsrc が作り直した版を入れられず "A different version is already
# installed" で転ぶので、あれば外して pkgsrc に作らせる。
want x11 && { pkg_delete -f x11-links > /dev/null 2>&1 || true; }

echo "--- build と install ---"
cd /usr/pkgsrc/zakinko/mule
# 同じ版が残っていると install が拒否されるので、作り直す前に外す
pkg_delete -f mule > /dev/null 2>&1 || true
# 公式バイナリの Canna-lib は tree の要求より古いことがある。ソースから
# 作らせると imake ごしに python まで引くので、入っているものを使わせる。
make PKG_OPTIONS.mule="$OPTS" \
     BUILDLINK_API_DEPENDS.Canna-lib="Canna-lib>=3.7" \
     BUILDLINK_ABI_DEPENDS.Canna-lib="Canna-lib>=3.7" \
     install
set +e

test -x $MULE || { echo "FAIL: $MULE が無い"; exit 1; }

rm -rf $CI_DIR; mkdir -p $CI_DIR
# にほんごのテスト (EUC-JP, 8 文字 16 バイト)
printf '\244\313\244\333\244\363\244\264\244\316\245\306\245\271\245\310\n' \
	> $CI_DIR/src.euc

# ------------------------------------------------------------------
echo "--- 1. 中核 (符号化・編集操作・byte-compile) ---"
# -l に渡すのは必ず通常ファイル。/dev/null を渡すと Emacs 19 のローダが
# キャラクタデバイスを掴んで不正なオブジェクトを作り、パッケージが健全でも
# INVALID DATATYPE で落ちる。
$MULE -batch -q -l "$HERE/mule-tests.el" > $CI_DIR/core.log 2>&1
rc=$?
note "exit=$rc"
if [ ! -s "$RES" ]; then
	echo "    FAIL: 結果ファイルが無い。mule が起動しなかったか即死した。"
	sed -n '1,20p' $CI_DIR/core.log
	exit 1
fi
# DONE が無ければ途中で死んでいる。どこまで進んだかは記録された行で分かる。
must DONE 1

must_match version 19.28
must mule-p yes
must nchars 8
must width  16
# find-charset-region が返すのは記号ではなく leading char の番号。
# 146 = 0x92 = LCJP (JIS X 0208)。日本語だけの buffer なのでこれ 1 つ。
must charset 146

# 符号化の往復。期待値をこちらで持たない形なので、私の符号表の
# 思い違いが混ざらない。
must rt-euc      same
must rt-sjis     same
must rt-jis      same
must rt-internal same
# 指定した符号化が本当に効いているか。効いていなければ往復は
# 何を指定しても通ってしまう。
must cross   differs
must mixed   same

# 実際に落ちたバイト列。往復が通っても、落ちたものが EUC-JP や
# Shift_JIS として正しいとは限らない。
must_bytes rt.euc  a4cba4dba4f3a4b4a4cea5c6a5b9a5c8
must_bytes rt.sjis 82c982d982f182b282cc836583588367
J=$(hexof $CI_DIR/rt.jis)
case "$J" in
1b2442*244b245b24732434244e254625392548*)
	note "rt.jis のバイト列 OK (ESC \$ B + 7bit)" ;;
*)	bad "rt.jis: ISO-2022-JP として正しくない: $J" ;;
esac

# 編集操作
must search   same
must replace  same
must regexp   same
must killyank same
must undo     same
must delchar  same
must upcase   same
# "a" "b" 日本語 を並べ替えた先頭。日本語の行があっても sort が落ちないこと。
must sort a

# skip_chars と get_local_map は、宣言が無いと LP64 で戻り値が切り詰められる。
# get_local_map が返すのは keymap で、整数と違って落ちれば必ず壊れる。
must skipchars 3,4
must whereis vector:1

# 日本語文字列を含む .el が compile を通り、.elc から読み直しても保つか
must bytecomp same

# Mule 2.3 の文字列長は内部表現のバイト数。JIS の 1 文字が 3 バイトなので
# 8 文字で 24。ここが動いたら内部表現が変わったということで、知らせに値する。
must length 24

# ------------------------------------------------------------------
echo "--- 2. 繰り返し起動しても同じ結果か ---"
# ダンプ済みバイナリは、初期化済みデータを復元して起動する。復元が
# 不完全だと「たまに落ちる」「2 回目から挙動が違う」という形で出る。
cp $RES $CI_DIR/first.txt
i=1; det=ok
while [ $i -le 5 ]; do
	rm -f $RES
	$MULE -batch -q -l "$HERE/mule-tests.el" > /dev/null 2>&1
	if ! cmp -s $RES $CI_DIR/first.txt; then
		det="ちがう ($i 回目)"
		diff $CI_DIR/first.txt $RES | sed -n '1,10p'
		break
	fi
	i=$((i + 1))
done
[ "$det" = ok ] && note "5 回とも同じ" || bad "起動ごとに結果が変わる: $det"

# ------------------------------------------------------------------
# 変換結果は端末の符号化に左右されないよう EUC-JP のバイト列で照合する。
#   日本語 = c6fc cbdc b8ec      変換 = cad1 b4b9
if want canna; then
	echo "--- 3. canna: ローマ字から漢字まで ---"
	# 辞書は libdata に入るが cannaserver が読むのは /var/dict/canna/canna
	mkdir -p /var/dict/canna/canna /var/dict/canna/group
	cp /usr/pkg/libdata/canna/* /var/dict/canna/canna/ 2>/dev/null
	chown -R daemon:daemon /var/dict/canna
	chmod 775 /var/dict/canna /var/dict/canna/canna /var/dict/canna/group
	# 既に動いていることがある。二重起動は失敗するので確かめてから。
	pgrep -q cannaserver || /usr/pkg/sbin/cannaserver -u daemon || true
	sleep 2
	if [ ! -S /tmp/.iroha_unix/IROHA ]; then
		bad "cannaserver が起動していない"
	else
		cat > $CI_DIR/canna.el <<'EL'
(defvar ci-dir (or (getenv "CI_DIR") "/tmp/mule-ci"))
(defun ci-out (name s)
  (set-buffer (get-buffer-create "o")) (erase-buffer) (insert s)
  (let ((file-coding-system '*euc-japan*))
    (write-region (point-min) (point-max) (expand-file-name name ci-dir) nil 'quiet)))
(canna-initialize)
(canna-do-function canna-func-japanese-mode)
(mapcar (function (lambda (c) (canna-key-proc c))) (append "nihongo" nil))
(canna-key-proc ?\ )
(canna-key-proc ?\C-m)
(ci-out "canna.out" canna-kakutei-string)
EL
		$MULE -batch -q -l $CI_DIR/canna.el > $CI_DIR/canna.log 2>&1
		H=$(hexof $CI_DIR/canna.out)
		if [ "$H" = c6fccbdcb8ec ]; then note "canna OK (nihongo -> 日本語)"
		else bad "canna が nihongo を 日本語 にしなかった: ${H:-<出力なし>}"; fi
	fi
fi

if want wnn4; then
	echo "--- 4. wnn: 読みから漢字まで ---"
	pgrep -q jserver || /usr/pkg/sbin/jserver || true
	sleep 2
	if [ ! -f /usr/pkg/lib/mule/19.28/lisp/eggrc ]; then
		bad "eggrc が入っていない (egg が辞書を登録できない)"
	else
		# にほんごのへんかん
		printf '\244\313\244\333\244\363\244\264\244\316\244\330\244\363\244\253\244\363\n' \
			> $CI_DIR/yomi.euc
		cat > $CI_DIR/wnn.el <<'EL'
(defvar ci-dir (or (getenv "CI_DIR") "/tmp/mule-ci"))
(load "egg") (load "wnn-egg")
(set-buffer (get-buffer-create "b"))
(let ((file-coding-system-for-read '*euc-japan*))
  (insert-file-contents (expand-file-name "yomi.euc" ci-dir)))
(goto-char (point-max))
(if (bolp) (delete-char -1))
(henkan-region (point-min) (point-max))
(let ((file-coding-system '*euc-japan*))
  (write-region (point-min) (point-max)
                (expand-file-name "wnn.out" ci-dir) nil 'quiet))
EL
		yes y | $MULE -batch -q -l $CI_DIR/wnn.el > $CI_DIR/wnn.log 2>&1
		H=$(hexof $CI_DIR/wnn.out)
		case "$H" in
		*c6fccbdcb8ec*) ;;
		*) bad "wnn の結果に 日本語 が無い: ${H:-<出力なし>}" ;;
		esac
		case "$H" in
		*cad1b4b9*) note "wnn OK (にほんごのへんかん -> 日本語の変換)" ;;
		*) bad "wnn の結果に 変換 が無い: ${H:-<出力なし>}" ;;
		esac
	fi
fi

if want x11; then
	echo "--- 5. X11: フレームが開いて日本語が扱えるか ---"
	# 判定は shell 側で行う。Emacs 19.28 の run-at-time は lib-src/timer の
	# 別プロセスに依存していて、この構成では発火しない。elisp のタイマーで
	# 自殺させる書き方にすると、mule が終わらずテストが固まる。
	# 前回の残骸が :99 を掴んでいると Xvfb は起動に失敗する。掃除してから。
	pkill Xvfb 2>/dev/null || true
	rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null || true
	sleep 1
	Xvfb :99 -screen 0 1024x768x24 > $CI_DIR/xvfb.log 2>&1 &
	XVFB=$!
	sleep 5
	if ! kill -0 $XVFB 2>/dev/null; then
		bad "Xvfb が起動しない"; sed -n '1,5p' $CI_DIR/xvfb.log
	else
		# (a) フレームが実際に X にマップされるか
		DISPLAY=:99 $MULE -q > $CI_DIR/xrun.log 2>&1 &
		M=$!
		sleep 15
		if ! kill -0 $M 2>/dev/null; then
			bad "mule が X 上で終了した"; sed -n '1,5p' $CI_DIR/xrun.log
		else
			DISPLAY=:99 xwininfo -root -tree > $CI_DIR/xwin.txt 2>/dev/null
			if grep -qi emacs $CI_DIR/xwin.txt; then
				note "フレーム OK ($(grep -i -m1 emacs $CI_DIR/xwin.txt | sed 's/^ *//'))"
			else
				bad "X にフレームがマップされなかった"
				sed -n '1,8p' $CI_DIR/xwin.txt
			fi
		fi
		kill $M 2>/dev/null || true; sleep 1

		# (b) X を掴んだ状態で日本語を扱い、自分で終わるか。端末版と
		#     同じ処理でも、Xt 版はリンクされているものが違う。2017 年に
		#     amd64 の Xt 版だけ core を吐いた記録があるのはここ。
		cat > $CI_DIR/x.el <<'EL'
(defvar ci-dir (or (getenv "CI_DIR") "/tmp/mule-ci"))
(set-buffer (get-buffer-create "x")) (erase-buffer)
(let ((file-coding-system-for-read '*euc-japan*))
  (insert-file-contents (expand-file-name "src.euc" ci-dir)))
(goto-char (point-max)) (if (bolp) (delete-char -1))
(set-buffer (get-buffer-create "r")) (erase-buffer)
(insert (format "ws=%s\n" window-system))
(insert (format "px=%s\n" (x-display-pixel-width)))
(save-excursion
  (set-buffer "x")
  (let ((file-coding-system '*junet*))
    (write-region (point-min) (point-max)
                  (expand-file-name "x.jis" ci-dir) nil 'quiet)))
(set-buffer "r")
(let ((file-coding-system '*noconv*))
  (write-region (point-min) (point-max)
                (expand-file-name "x.txt" ci-dir) nil 'quiet))
(kill-emacs 0)
EL
		rm -f $CI_DIR/x.txt $CI_DIR/x.jis
		DISPLAY=:99 $MULE -q -l $CI_DIR/x.el > $CI_DIR/xl.log 2>&1
		xrc=$?
		if [ ! -s $CI_DIR/x.txt ]; then
			bad "X 版が結果を書かずに終わった (exit=$xrc)"
			sed -n '1,10p' $CI_DIR/xl.log
		else
			W=$(sed -n 's/^ws=//p' $CI_DIR/x.txt)
			[ "$W" = x ] && note "window-system = x" \
				|| bad "window-system が x でない: $W"
			note "画面幅 = $(sed -n 's/^px=//p' $CI_DIR/x.txt) px"
			case "$(hexof $CI_DIR/x.jis)" in
			1b2442*) note "X 版でも多バイトの書き出し OK" ;;
			*) bad "X 版の ISO-2022-JP 書き出しが壊れている" ;;
			esac
			[ "$xrc" = 0 ] || bad "X 版の終了状態が $xrc"
		fi
		kill $XVFB 2>/dev/null || true
	fi
fi

# ------------------------------------------------------------------
echo "--- 6. 後始末の確認 ---"
# ダンプ済みバイナリは黙って core を吐いてから何食わぬ顔で終わることがある。
C=$(find $CI_DIR /tmp /var/tmp -maxdepth 2 -name '*.core' -newer $CI_DIR/src.euc 2>/dev/null)
if [ -n "$C" ]; then bad "core を吐いている: $C"; else note "core なし"; fi

echo
if [ $fail -eq 0 ]; then
	echo "=== 通った: NetBSD ${REL}/${ARCH} \"${OPTS}\" ==="
	exit 0
else
	echo "=== 落ちた: NetBSD ${REL}/${ARCH} \"${OPTS}\" ==="
	exit 1
fi
