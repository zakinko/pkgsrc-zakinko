#!/bin/sh
# pkgsrc の載った NetBSD の中で走る。zakinko/mule (Mule 1.1) を組んで、
# 実際に日本語が編集できるところまで確かめる。
#
#   VERIFY_OPTS  PKG_OPTIONS.mule に渡す文字列。空なら package の既定
#   $1           run-in-qemu.sh が渡す package 名 (zakinko/mule)。使わない
#
# 名前は build-on-bsd.sh の探し方に合わせてある。verify-<package の
# ディレクトリ名>.sh で、zakinko/mule (1.1) はこの名前、zakinko/mule2 (2.3)
# は verify-mule2.sh。例外を作ると、表を読まないと何が呼ばれるか分からなく
# なり、しかも表の更新漏れは黙って汎用の verify-pkg.sh に落ちる形で出る。
#
# ややこしいのは履歴の側で、この名前は 2026 年 8 月 28 日まで Mule 2.3 の
# 検査だった。8d71ae8 で mule という名前が 1.1 を指すようになり、2.3 側は
# verify-mule2.sh へ移ったので、規則どおりこの名前が 1.1 の検査になった。
#
# verify-mule2.sh (Mule 2.3) と対になる。踏む項目は同じだが、1.1 は別物で、
# 検査の書き方が変わるところがいくつかある。
#
#   * lisp は share/mule/18.59 に入る (2.3 は lib/mule/19.28)
#   * egg は (load "egg") だけでよい。wnn-egg.el は 2.3 で入ったもの
#   * eggrc は同梱の eggrc-v41 を egg が自分で読む。置き直す段は要らない
#   * -q は option ではない。18.59 はそれを開くべきファイル名と見て、
#     ~/.emacs も読む。HOME を空のディレクトリへ向けて逃げる
#   * batch で標準入力が EOF になると黙って終わる (終了コードは 0 のまま)。
#     Wnn は利用者辞書が無いと初回に「作るか」と訊くので yes y | で食わせる。
#     答えを使い切ると、途中で止まったように見えて成否が分からなくなる
#
# 判定に stderr は使わない。結果ファイルの中身と、書き出させた符号化済み
# ファイルのバイト列だけで見る。ビルドが通っただけでは通したことにしない。
# 1994 年のこのコードは「ビルドは通るのにダンプ済みバイナリが起動時に
# 落ちる」「変換サーバにつながるのに読みがそのまま返る」という壊れ方をする。
#
# 検査は最初の失敗で止めない。全部走らせて最後にまとめて落とす。

OPTS=${VERIFY_OPTS:-}

PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin:/usr/X11R7/bin
export PATH
unset PKG_PATH

MULE=$PREFIX/bin/mule
CI_DIR=/tmp/mule11-ci
export CI_DIR
rm -rf $CI_DIR; mkdir -p $CI_DIR/home
# 18.59 は -q を option として扱わないので、~/.emacs を読ませない道が無い。
# 空の HOME を与える。.Xdefaults の Emacs.Font を拾って X 版が Fatal error
# (6) で落ちる、という当時からの躓きもこれで避けられる。
HOME=$CI_DIR/home
export HOME

OS=$(uname -s)
ARCH=$(uname -m)
REL=$(uname -r | sed -e 's/_.*//')
JOBS=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
_mb=$(sysctl -n hw.physmem64 2>/dev/null || sysctl -n hw.physmem 2>/dev/null || echo 0)
_mb=$((_mb / 1048576))
if [ "$_mb" -gt 0 ]; then
	_bymem=$((_mb / 1024)); [ "$_bymem" -lt 1 ] && _bymem=1
	[ "$_bymem" -lt "$JOBS" ] && JOBS=$_bymem
fi
echo "=== ${OS} ${REL} / ${ARCH} / PKG_OPTIONS.mule=\"${OPTS}\" ==="
echo "    資源: ${JOBS} 並列 (メモリ ${_mb} MB)"

fail=0
note() { echo "    $*"; }
bad()  { echo "    FAIL: $*"; fail=1; }
want() { case " $OPTS " in *" $1 "*) return 0 ;; esac; return 1; }
hexof() { od -An -tx1 "$1" 2>/dev/null | tr -d ' \n'; }

# 日本語 = c6fc cbdc b8ec   変換 = cad1 b4b9   にほんご… = EUC の読み
EUC_NIHONGO=c6fccbdcb8ec
SJIS_NIHONGO=93fa967b8cea
JIS_NIHONGO=1b2442467c4b5c386c1b2842

build_install() {
	_dir=$1; shift
	( cd "$_dir" && make "$@" MAKE_JOBS="$JOBS" install && echo __BUILD_OK__ ) \
		2>&1 | tail -40 | tee /tmp/build.log
	grep -q '^__BUILD_OK__$' /tmp/build.log
}

echo "--- 依存をバイナリで入れる ---"
PKG_PATH="http://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/${ARCH}/${REL}/All/"
export PKG_PATH
for p in gmake mozilla-rootcerts; do pkg_add -U "$p" || true; done
want wnn4 && { pkg_add -U ja-FreeWnn-lib ja-FreeWnn-server || true; }
mozilla-rootcerts install > /dev/null 2>&1 || true
# Canna と x11-links は公式バイナリのほうが古いことがあり、残っていると
# pkgsrc が作り直した版を入れられず "A different version is already
# installed" で転ぶ。あれば外して pkgsrc に作らせる。
want canna && { pkg_delete -f Canna-lib Canna-server Canna-dict >/dev/null 2>&1 || true; }
want x11   && { pkg_delete -f x11-links >/dev/null 2>&1 || true; }
unset PKG_PATH
# 1.1 と 2.3 は bin/mule と bin/m2ps を同じ名前で入れる。作り直しのときに
# 残っていると install が拒まれるので先に外す。
pkg_delete -f 'mule-[0-9]*' 'mule2-[0-9]*' >/dev/null 2>&1 || true

echo "=== 1. 組んで入れる ==="
if [ -n "$OPTS" ]; then
	build_install "$TREE/zakinko/mule" PKG_OPTIONS.mule="$OPTS" || \
		{ bad "組めない"; exit 1; }
else
	build_install "$TREE/zakinko/mule" || { bad "組めない"; exit 1; }
fi
note "入った: $(pkg_info -E 'mule-[0-9]*' 2>/dev/null || echo '?')"
[ -x "$MULE" ] || { bad "$MULE が無い"; exit 1; }
want canna && { ldd "$MULE" | grep -q libcanna && note "libcanna に繋がっている" \
	|| bad "canna を指定したのに繋がっていない"; }
want wnn4  && { ldd "$MULE" | grep -q libwnn && note "libwnn に繋がっている" \
	|| bad "wnn4 を指定したのに繋がっていない"; }

echo "=== 2. 符号化・検索・置換・byte-compile ==="
cd $CI_DIR
printf '(setq s "\306\374\313\334\270\354")\n(set-buffer (get-buffer-create "o"))\n(insert (format "%%s %%d\\n" emacs-version (length s)))\n(set-buffer (get-buffer-create "w"))\n(insert "\244\242" s "\244\244")\n(goto-char (point-min))\n(setq f (search-forward s nil t))\n(goto-char (point-min))\n(while (search-forward s nil t) (replace-match "ZZ" t t))\n(setq r (buffer-string))\n(set-buffer "o")\n(insert (format "search=%%s replace=%%s\\n" (if f "ok" "NG") (if (string-match "ZZ" r) "ok" "NG")))\n(set-buffer (get-buffer-create "e"))\n(insert s)\n(setq file-coding-system *euc-japan*)\n(write-region (point-min) (point-max) "euc.bin" nil (quote q))\n(setq file-coding-system *sjis*)\n(write-region (point-min) (point-max) "sjis.bin" nil (quote q))\n(setq file-coding-system *junet*)\n(write-region (point-min) (point-max) "junet.bin" nil (quote q))\n(set-buffer "o")\n(setq file-coding-system *euc-japan*)\n(write-region (point-min) (point-max) "basic.txt" nil (quote q))\n' > basic.el
$MULE -batch -l ./basic.el > basic.log 2>&1 || true
if [ ! -s basic.txt ]; then
	bad "起動して結果を書くところまで行かない"; sed -n '1,10p' basic.log | sed 's/^/      /'
else
	grep -q '^18.59' basic.txt && note "版 $(head -1 basic.txt)" || bad "版が読めない: $(head -1 basic.txt)"
	grep -q ' 9$' basic.txt || bad "内部表現の長さが 9 でない: $(head -1 basic.txt)"
	grep -q 'search=ok replace=ok' basic.txt && note "日本語の検索と置換" \
		|| bad "検索か置換が通らない: $(sed -n 2p basic.txt)"
fi
[ "$(hexof euc.bin)"   = $EUC_NIHONGO ]  && note "EUC-JP で書き出し"   || bad "EUC が違う: $(hexof euc.bin)"
[ "$(hexof sjis.bin)"  = $SJIS_NIHONGO ] && note "Shift_JIS で書き出し" || bad "SJIS が違う: $(hexof sjis.bin)"
[ "$(hexof junet.bin)" = $JIS_NIHONGO ]  && note "JUNET で書き出し"    || bad "JUNET が違う: $(hexof junet.bin)"

printf '(defconst zz "\306\374\313\334\270\354")\n' > j.el
$MULE -batch -f batch-byte-compile j.el > bc.log 2>&1 || true
printf '(load (expand-file-name "j.elc"))\n(set-buffer (get-buffer-create "o"))\n(insert zz)\n(setq file-coding-system *euc-japan*)\n(write-region (point-min) (point-max) "elc.bin" nil (quote q))\n' > l.el
$MULE -batch -l ./l.el > bc2.log 2>&1 || true
[ "$(hexof elc.bin)" = $EUC_NIHONGO ] && note "byte-compile して .elc から読み直す" \
	|| bad ".elc の中身が違う: $(hexof elc.bin)"

i=1; ref=; det=ok
while [ $i -le 5 ]; do
	$MULE -batch -l ./basic.el > /dev/null 2>&1 || true
	h="$(hexof basic.txt)$(hexof euc.bin)"
	[ -z "$ref" ] && ref=$h
	[ "$h" = "$ref" ] || det=ng
	i=$((i + 1))
done
[ $det = ok ] && note "五回起動して同じ" || bad "起動ごとに結果が変わる"

if want canna; then
	echo "=== 3. canna: ローマ字から漢字まで ==="
	# サーバと辞書は mule の依存ではない (options.mk が読むのは canna-lib の
	# buildlink3.mk だけ) ので、ここで入れる。
	#
	# まずバイナリを試す。run-in-qemu.sh の既定のツリーが四半期枝になった
	# ので、公式バイナリと版が揃うようになった。
	#
	# 組むほうを先にすると、素のイメージでは転ぶ。canna-server は
	# PKG_GROUPS/PKG_USERS で自分の group を要求するが、それが作られるのは
	# install の段で、pkg_create はその前に走る。名前の無い gid を持つ
	# ファイルを詰めようとして
	#
	#	pkg_create: unknown group name for gid 125
	#
	# で止まる。techne のように既に canna が入っている箱では group が在る
	# ので気づけない。
	PKG_PATH="http://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/${ARCH}/${REL}/All/" \
		pkg_add -U Canna-server Canna-dict > /dev/null 2>&1 || true
	if [ ! -x $PREFIX/sbin/cannaserver ]; then
		# バイナリが無ければ組む。その前に group と user を作っておく。
		CG=$(cd $TREE/inputmethod/canna-server && make show-var VARNAME=CANNA_GROUP 2>/dev/null)
		CU=$(cd $TREE/inputmethod/canna-server && make show-var VARNAME=CANNA_USER 2>/dev/null)
		[ -n "$CG" ] && { grep -q "^$CG:" /etc/group  || groupadd "$CG" || true; }
		[ -n "$CU" ] && { grep -q "^$CU:" /etc/passwd || useradd -g "$CG" -d /nonexistent -s /sbin/nologin "$CU" || true; }
		for d in canna-server canna-dict; do
			build_install "$TREE/inputmethod/$d" || bad "$d を組めない"
		done
	fi
	# 辞書は libdata に入るが cannaserver が読むのは /var/dict/canna/canna
	mkdir -p /var/dict/canna/canna /var/dict/canna/group
	cp $PREFIX/libdata/canna/* /var/dict/canna/canna/ 2>/dev/null
	chown -R daemon:daemon /var/dict/canna
	chmod 775 /var/dict/canna /var/dict/canna/canna /var/dict/canna/group
	pgrep -q cannaserver || $PREFIX/sbin/cannaserver -u daemon || true
	sleep 2
	if [ ! -S /tmp/.iroha_unix/IROHA ]; then
		bad "cannaserver が起動していない"
	else
		cat > $CI_DIR/canna.el <<'EL'
(defvar ci-dir (or (getenv "CI_DIR") "."))
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
		rm -f canna.out
		$MULE -batch -l $CI_DIR/canna.el > canna.log 2>&1 || true
		[ "$(hexof canna.out)" = $EUC_NIHONGO ] && note "canna OK (nihongo -> 日本語)" \
			|| bad "canna が変換しない: $(hexof canna.out)"
	fi
fi

if want wnn4; then
	echo "=== 4. wnn: 読みから漢字まで ==="
	pgrep -q jserver || $PREFIX/sbin/jserver || true
	sleep 2
	# にほんごのへんかん
	printf '\244\313\244\333\244\363\244\264\244\316\244\330\244\363\244\253\244\363\n' > $CI_DIR/yomi.euc
	cat > $CI_DIR/wnn.el <<'EL'
(defvar ci-dir (or (getenv "CI_DIR") "."))
(load "egg")
(set-buffer (get-buffer-create "b"))
(let ((file-coding-system-for-read '*euc-japan*))
  (insert-file-contents (expand-file-name "yomi.euc" ci-dir)))
(goto-char (point-max))
(if (bolp) (delete-char -1))
(henkan-region (point-min) (point-max))
(let ((file-coding-system '*euc-japan*))
  (write-region (point-min) (point-max) (expand-file-name "wnn.out" ci-dir) nil 'quiet))
EL
	rm -f wnn.out
	# 初回は利用者辞書を作るかを訊いてくる。答えを切らすと標準入力が EOF に
	# なり、Emacs 18 はそこで黙って終わる。yes で無限に食わせる。
	yes y | $MULE -batch -l $CI_DIR/wnn.el > wnn.log 2>&1 || true
	H=$(hexof wnn.out)
	case "$H" in *$EUC_NIHONGO*) note "wnn: 日本語 が出る" ;;
		*) bad "wnn の結果に 日本語 が無い: ${H:-<出力なし>}" ;; esac
	case "$H" in *cad1b4b9*) note "wnn: 変換 が出る" ;;
		*) bad "wnn の結果に 変換 が無い: ${H:-<出力なし>}" ;; esac
fi

# x11 option を足したので、外した構成では X 版が建たない。Xvfb が無い箱
# (Linux のコンテナなど) でも飛ばす。
if want x11 && { [ -x /usr/X11R7/bin/Xvfb ] || command -v Xvfb > /dev/null 2>&1; }; then
	echo "=== 5. X11: フレームが開くか ==="
	pkill Xvfb 2>/dev/null || true
	rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null || true
	sleep 1
	Xvfb :99 -screen 0 1024x768x24 > $CI_DIR/xvfb.log 2>&1 &
	XVFB=$!
	sleep 5
	if ! kill -0 $XVFB 2>/dev/null; then
		bad "Xvfb が起動しない"; sed -n '1,5p' $CI_DIR/xvfb.log | sed 's/^/      /'
	else
		# 判定は elisp に書かせる。Emacs 18 に run-at-time は無いので、
		# sit-for で数秒生かしてから自分で終わらせる。落ちていれば
		# x.txt が残らない。
		printf '(set-buffer (get-buffer-create "o"))\n(insert (format "ws=%%s\\n" window-system))\n(sit-for 5)\n(insert "alive\\n")\n(write-region (point-min) (point-max) "x.txt" nil (quote q))\n(kill-emacs)\n' > $CI_DIR/x.el
		rm -f $CI_DIR/x.txt
		( cd $CI_DIR && DISPLAY=:99 $MULE -l ./x.el > xrun.log 2>&1 ) &
		MPID=$!
		sleep 4
		DISPLAY=:99 xwininfo -root -children > $CI_DIR/xwin.txt 2>/dev/null || true
		wait $MPID
		grep -q 'ws=x' $CI_DIR/x.txt 2>/dev/null && note "window-system が x" \
			|| { bad "X で上がらない"; sed -n '1,5p' $CI_DIR/xrun.log | sed 's/^/      /'; }
		grep -q alive $CI_DIR/x.txt 2>/dev/null && note "5 秒生きている (core を吐かない)" \
			|| bad "X 上で落ちた"
		grep -qi mule $CI_DIR/xwin.txt && note "X に窓が出る" || bad "窓が見つからない"
		kill $XVFB 2>/dev/null || true
	fi
fi

echo
if [ $fail -eq 0 ]; then echo "=== 全部通った ==="; else echo "=== 転けた ==="; fi
exit $fail
