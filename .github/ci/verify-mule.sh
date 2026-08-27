#!/bin/sh
# pkgsrc の載った BSD の中で走る。mule を組んで、実際に日本語が編集できる
# ところまで確かめる。
#
#   $1  PKG_OPTIONS.mule2 に渡す文字列
#
# NetBSD からは run-in-qemu.sh が、それ以外の BSD からは build-on-bsd.sh が
# 呼ぶ。違うのは依存の入れ方だけで、検査は同じものを通す。
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

# 置き場所は呼ぶ側が決める。build-on-bsd.sh は Darwin で /opt/pkg、Haiku で
# /boot/home/pkg を使い (前者は SIP で /usr に書けず、後者に /usr は無い)、
# ツリーもそこへ寄せて PREFIX と TREE で渡してくる。NetBSD の
# run-in-qemu.sh は base の場所をそのまま使うので何も渡さない。
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}

# X は NetBSD が /usr/X11R7、OpenBSD が /usr/X11R6、FreeBSD は pkg の
# /usr/local に入る。
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
PATH=$PATH:/usr/X11R7/bin:/usr/X11R6/bin:/usr/local/bin
export PATH
unset PKG_PATH

MULE=$PREFIX/bin/mule
CI_DIR=/tmp/mule-ci
RES=$CI_DIR/results.txt
export CI_DIR
HERE=$(cd "$(dirname "$0")" && pwd)

OS=$(uname -s)
ARCH=$(uname -m)
# 依存を建てる回数が多いので並列にする。並列で壊れる package は pkgsrc 側が
# MAKE_JOBS_SAFE=no で除いてくれるので、こちらは台数を渡すだけでよい。
#
# ただしコア数をそのまま使うと、メモリの少ない箱で落ちる。cmake や re2c の
# C++ は 1 本あたり 1 GB 近く要ることがあり、CI のイメージは no_swap=YES で
# 焼いてあって swap が無いので、足りなければその場で殺される (実際
# "Killed signal terminated program cc1plus" で転けた)。1 本あたり 1 GB を
# 見て、コア数と少ないほうを採る。
JOBS=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 1)
_mb=$(sysctl -n hw.physmem64 2>/dev/null || sysctl -n hw.physmem 2>/dev/null || echo 0)
_mb=$((_mb / 1048576))
if [ "$_mb" -gt 0 ]; then
	_bymem=$((_mb / 1024))
	[ "$_bymem" -lt 1 ] && _bymem=1
	[ "$_bymem" -lt "$JOBS" ] && JOBS=$_bymem
fi
echo "    資源: ${JOBS} 並列 (CPU $(sysctl -n hw.ncpu 2>/dev/null || echo ?), メモリ ${_mb} MB)"
df -h / /tmp 2>/dev/null | sed 's/^/    /'
REL=$(uname -r | sed -e 's/_.*//')
echo "=== ${OS} ${REL} / ${ARCH} / PKG_OPTIONS.mule2=\"${OPTS}\" ==="
# NetBSD は gcc、FreeBSD と OpenBSD は clang。どちらでも cc で当たる。
cc --version 2>/dev/null | head -1

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
set -e
if [ "$OS" = NetBSD ]; then
	echo "--- 依存をバイナリで入れる ---"
	PKG_PATH="http://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/${ARCH}/${REL}/All/"
	export PKG_PATH
	for p in gmake gtexinfo mozilla-rootcerts; do pkg_add -U "$p" || true; done
	# Canna はバイナリで入れない。公式は 3.7pl3nb1 で tree は 3.8 を求める
	# ので、古いほうが入っていると pkgsrc が作り直した版を入れられず
	# x11-links と同じ "A different version is already installed" で転ぶ。
	# サーバと辞書は mule の依存には入らない (options.mk が読むのは
	# canna-lib の buildlink3.mk だけ) ので、あとで名指しで組ませる。
	want wnn4  && { pkg_add -U ja-FreeWnn-lib ja-FreeWnn-server || true; }
	mozilla-rootcerts install > /dev/null 2>&1 || true
	unset PKG_PATH

	# x11-links はバイナリで入れない。symlink を張るだけの小さな
	# パッケージで、公式バイナリは pkgsrc current より古いことがある。
	# 古いほうが残っていると pkgsrc が作り直した版を入れられず
	# "A different version is already installed" で転ぶので、あれば
	# 外して pkgsrc に作らせる。
	want x11 && { pkg_delete -f x11-links > /dev/null 2>&1 || true; }

	# Canna も同じ。まっさらなイメージなら入っていないが、作り直しの
	# ときに古いものが残っていると同じ形で転ぶ。
	want canna && { pkg_delete -f Canna-lib Canna-server Canna-dict \
		> /dev/null 2>&1 || true; }

	# tree の要求が公式バイナリより新しくても緩めない。足りなければ
	# pkgsrc が自分で作り直す。緩めると、実際に使われる組み合わせでは
	# ないものを検査することになる。
	MKARGS=
	PKGMAKE=make
else
	# NetBSD 以外に公式のバイナリ集合は無い。依存は pkgsrc に組ませ、
	# ついでに package も作らせる。build-on-bsd.sh が PACKAGES を
	# キャッシュに向けてあるので、次の回はそこから入る。
	echo "--- 依存は pkgsrc に組ませる ---"
	MKARGS="DEPENDS_TARGET=package-install"
	# base の make は FreeBSD も OpenBSD も pkgsrc には使えない。
	# bootstrap が入れた bmake を呼ぶ。
	PKGMAKE=$PREFIX/bin/bmake
fi

# pkgsrc に組ませる。第 1 引数がディレクトリ、残りは make に渡す。
#
# NetBSD では tree と公式バイナリの出どころが違う。tree は pkgsrc current、
# バイナリは動かしている release の四半期枝なので、current が版を上げた
# ものは作り直しになる。その作り直した版を入れるところで pkg_add が
# 「A different version is already installed」と言って拒む。名指しされた
# ほうを外してやり直せば済むので、そうする。current が実際に上げたものだけ
# が建て直され、残りはバイナリのまま使える。
#
# 四半期枝の tree を取れば版ずれ自体が起きず速くもなるが、それはしない。
# 直す先は current なので、current で検査しなければ意味がない。
#
# 成否は make の終了状態で見たいが、tee を通すと拾えない。目印を出させて
# それを見る。pipefail は NetBSD 以外の sh に無いので使わない。
build_install() {
	_dir=$1; shift
	_i=0
	while :; do
		( cd "$_dir" && $PKGMAKE "$@" MAKE_JOBS="$JOBS" $MKARGS install &&
		  echo "__BUILD_OK__" ) 2>&1 | tee /tmp/build.log
		if grep -q '^__BUILD_OK__$' /tmp/build.log; then
			return 0
		fi

		_old=$(sed -n 's/.*is already installed: *\([^ ]*\).*/\1/p' \
			/tmp/build.log | tail -1)
		_i=$((_i + 1))
		if [ -z "$_old" ] || [ $_i -gt 20 ]; then
			return 1
		fi
		echo "    古い $_old が邪魔をするので外してやり直す ($_i)"
		pkg_delete -f "$_old" > /dev/null 2>&1 || true
	done
}

# DragonFly では上流の devel/libuuid が建たない (util-linux が組めない)。
# mule は makeinfo を要り、そこから gtexinfo、help2man、gettext-tools、
# python313 と辿って libuuid に行き当たるので、これが建たないと configure
# まで届かない。zakinko/libuuid は上流の Makefile.common に
# CONFIGURE_ENV.DragonFly を一行足しただけの差し替えで、同じ名前の
# パッケージなので、先に入れてしまえば以降の依存はそれで満たされる。
#
# 置き場が overlay/devel/libuuid から zakinko/libuuid へ移った。無い版でも
# 動くよう、在るときだけ組む。
if [ "$OS" = DragonFly ] && [ -d "$TREE/zakinko/libuuid" ]; then
	echo "--- 先に libuuid を差し替える ---"
	build_install $TREE/zakinko/libuuid || bad "libuuid を組めない"
fi

echo "--- build と install ---"
# 同じ版が残っていると install が拒否されるので、作り直す前に外す
pkg_delete -f mule2 > /dev/null 2>&1 || true
build_install $TREE/zakinko/mule2 PKG_OPTIONS.mule2="$OPTS" || {
	echo "FAIL: mule を組めない"
	exit 1
}
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
	# サーバと辞書は mule の依存ではないので、ここで組ませる。lib と同じ
	# tree から作られるので版が揃う。
	for d in canna-server canna-dict; do
		build_install $TREE/inputmethod/$d ||
			bad "$d を組めない"
	done
	# 辞書は libdata に入るが cannaserver が読むのは /var/dict/canna/canna
	mkdir -p /var/dict/canna/canna /var/dict/canna/group
	cp $PREFIX/libdata/canna/* /var/dict/canna/canna/ 2>/dev/null
	chown -R daemon:daemon /var/dict/canna
	chmod 775 /var/dict/canna /var/dict/canna/canna /var/dict/canna/group
	# 既に動いていることがある。二重起動は失敗するので確かめてから。
	# NetBSD 9.4 の pgrep には -q が無い (10.0 から)。出力を捨てて数だけ見る。
	pgrep cannaserver > /dev/null 2>&1 || $PREFIX/sbin/cannaserver -u daemon || true
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
	pgrep jserver > /dev/null 2>&1 || $PREFIX/sbin/jserver || true
	sleep 2
	if [ ! -f $PREFIX/lib/mule/19.28/lisp/eggrc ]; then
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
# X 版が落ちたとき、どこで落ちたかを VM の中で取る。core を持ち出さずに
# 済むよう gdb に走らせて bt だけ読む。9.4/amd64 でここが SIGSEGV になる。
# 2017 年に tsutsui が「-nw は動くが Xt 版は core を吐く」と XXX で残したのと
# 同じ形なら、宣言の漏れた関数が bt に出る。Xt は XtPointer 越しに
# Lisp_Object を往復させる経路が多く、宣言が無いと暗黙の int に落ちて
# LP64 で上位 32bit が消える。
xbt_l() {
	command -v gdb > /dev/null 2>&1 || { note "gdb が無いので bt は取れない"; return; }
	note "elisp を読ませた側で落ちた場所を見る"
	DISPLAY=:99 gdb -batch -ex run -ex bt --args "$MULE" -q -l "$CI_DIR/x.el" 2>&1 |
		grep -vE '^\[New |^\[Thread |^Reading symbols' | head -30 | sed 's/^/      /'
}

xbt() {
	command -v gdb > /dev/null 2>&1 || { note "gdb が無いので bt は取れない"; return; }
	note "落ちた場所を gdb で見る"
	DISPLAY=:99 gdb -batch -ex run -ex bt --args "$MULE" -q 2>&1 |
		grep -vE '^\[New |^\[Thread |^Reading symbols' | head -30 | sed 's/^/      /'
}

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
			xbt
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
			# 139 は SIGSEGV (128 + 11)。落ちたなら場所を見る。
			[ "$xrc" -ge 128 ] && xbt_l
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
	echo "=== 通った: ${OS} ${REL}/${ARCH} \"${OPTS}\" ==="
	exit 0
else
	echo "=== 落ちた: ${OS} ${REL}/${ARCH} \"${OPTS}\" ==="
	exit 1
fi
