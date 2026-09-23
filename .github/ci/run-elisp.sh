#!/bin/sh
#
# 入った elisp package を実際に走らせる。
#
#	sh run-elisp.sh <package> <emacs の binary>
#	例: sh run-elisp.sh zakinko/tamago /usr/pkg/bin/emacs-30.2-nox11
#
# 建って入って外せる、までは verify-pkg.sh が見る。それが全部通っていても
# 使えないことがある。2026-09-23 に四つのうち三つがそうだった。
#
#	tamago       入力メソッドが十一個とも (void-function make-local-hook)
#	iiimecf      同じ形が lisp/iiimp.el に二箇所
#	emacs-ilisp  (load "ilisp") が (void-function member*)
#
# 落ちる呼び所が関数の中に在ると byte-compile は警告にしかしないので、
# rc=0 で素通りする。emacs-ilisp は建てる側の ilisp-mak.el が自分で
# (require 'cl) していたので、compile 時だけ名前が在るという形だった。
#
# だから入口を実際に呼ぶ。package ごとに呼び方が違うので、ここに並べる。
set -u

PKG=$1
EMACS=$2
# 第三引数は試験用に木を直接指すためのもの。CI では渡さない。
LISPROOT=${3:-}

[ -x "$EMACS" ] || { echo "FAIL: $EMACS が無い"; exit 1; }

# 走らせ方を書いていない package は、置き場を探す前に抜ける。探してから
# 抜けると「lisp が見つからない」で落ちて、書いていないだけなのに不合格に
# 見える (自己試験で踏んだ)。
case ${PKG##*/} in
elscreen|tamago|emacs-ilisp|iiimecf) ;;
*) echo "SKIP: $PKG の走らせ方を書いていない"; exit 0 ;;
esac

# 入った lisp の置き場は **推測しない。**directory の名前が package の名前と
# 一致しない (emacs-ilisp は ilisp/、tamago は egg/)。入った file を pkg_info
# に訊いて、el を持つ directory を全部 load-path へ入れる。tamago は
# egg/ egg/its/ egg/egg/ の三段に分かれていて、一つでは足りない。
if [ -n "$LISPROOT" ]; then
	DIRS=$(find "$LISPROOT" -name '*.el' -exec dirname {} \; | sort -u)
else
	DIRS=$(pkg_info -qL "${PKG##*/}" 2>/dev/null |
		sed -n 's|/[^/]*\.elc*$||p' | sort -u)
fi
[ -n "$DIRS" ] || { echo "FAIL: $PKG の lisp が見つからない"; exit 1; }

LARGS=""
for d in $DIRS; do
	[ -d "$d" ] || continue
	LARGS="$LARGS -L $d"
done
[ -n "$LARGS" ] || { echo "FAIL: $PKG の lisp の置き場が無い"; exit 1; }
echo "--- lisp:"
for d in $DIRS; do echo "      $d"; done

# 成功の印は実行時に (concat "RUN" "-OK") で組み立てる。**source に書いた
# 印を探してはいけない。**batch の backtrace は eval した式をそのまま印字
# するので、式の中に印が書いてあると、落ちた回の出力にも印が出る。それで
# 壊した木を一度通した (2026-09-23、自己試験で見つけた)。
#
# rc も見る。batch で捕まえていない error が出れば emacs は非 0 で終わる。
# 印と rc の両方が揃ったときだけ OK にする。
run () {  # $1 = 説明  $2 = elisp
	out=$("$EMACS" -batch -q --no-site-file $LARGS --eval "$2" 2>&1)
	rc=$?
	echo "$out" | sed 's/^/    /'
	if [ $rc -ne 0 ]; then
		echo "  FAIL: $1 (emacs が rc=$rc)"
		return 1
	fi
	case $out in
	*RUN-OK*) echo "  OK: $1" ;;
	*)        echo "  FAIL: $1 (印が出ていない)"; return 1 ;;
	esac
}

case ${PKG##*/} in
elscreen)
	run "画面を作って切り替えて消す" '
(progn (require (quote elscreen)) (elscreen-start)
  (elscreen-create) (elscreen-create)
  (elscreen-goto 1) (elscreen-kill 2)
  (if (equal (elscreen-get-screen-list) (list 1 0))
      (princ (concat "RUN" "-OK\n"))
    (princ (format "screen list=%S\n" (elscreen-get-screen-list)))))'
	;;
tamago)
	run "入力メソッドを十一個とも起動する" '
(progn (load "leim-list")
  (let ((bad 0)
        (ms (list "japanese-egg-anthy" "japanese-egg-canna" "japanese-egg-sj3"
                  "japanese-egg-wnn" "korean-egg-wnn" "chinese-cns-egg-wnn-zy"
                  "chinese-cns-egg-wnn-py" "chinese-gb-egg-wnn-wb"
                  "chinese-gb-egg-wnn-qm" "chinese-gb-egg-wnn-zy"
                  "chinese-gb-egg-wnn-py")))
    (dolist (m ms)
      (condition-case e (with-temp-buffer (activate-input-method m))
        (error (setq bad (1+ bad)) (princ (format "%s %S\n" m e)))))
    (if (= bad 0) (princ (format "%d 個とも起動 %s\n" (length ms) (concat "RUN" "-OK")))
      (princ (format "%d 個が起動失敗\n" bad)))))'
	;;
emacs-ilisp)
	run "ilisp を load して入口が生えるか" '
(progn (load "ilisp")
  (if (and (fboundp (quote run-ilisp)) (fboundp (quote common-lisp)))
      (princ (concat "RUN" "-OK\n"))
    (princ "run-ilisp か common-lisp が無い\n")))'
	;;
iiimecf)
	run "iiimcf-sc を require する" '
(progn (require (quote iiimcf-sc)) (princ (concat "RUN" "-OK\n")))'
	;;
*)
	# 頭の一覧が通した名前はここに枝が在るはず。無いなら二つの一覧が
	# 食い違っている。SKIP にすると黙って素通りするので落とす。
	echo "FAIL: $PKG は頭の一覧に在るのに走らせ方が無い"
	exit 1
	;;
esac
