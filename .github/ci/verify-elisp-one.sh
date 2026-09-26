#!/bin/sh
#
# zakinko/ の elisp package を一つ、新しい Emacs で建てて入れて外す。
#
#	sh verify-elisp-one.sh <package> [<emacs の型>]
#	例: sh verify-elisp-one.sh zakinko/elscreen emacs30nox
#
# elisp17.yml は emacs20/21 と XEmacs を見る口で、そこには新しい Emacs が
# 無い。emacs-new.yml は 408 個を一括で回す口で、一つだけ試すには重い。
# 版を上げた package を一つ確かめたいときに、この口を使う。
set -u

# NetBSD の素の箱は PATH に /usr/sbin を持たない。pkg_info がそこに在る
# ので、入れないと「入っていない」と読んで毎回 emacs を入れ直しにいく。
# 2026-09-23 の run 35823870886 の log に pkg_info: not found が二度出て
# いる。verify-pkg.sh は自分で通しているのでそちらは効いていた。
PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/pkg/bin:/usr/pkg/sbin
export PATH

# run-in-qemu.sh は package を位置引数で、それ以外を VERIFY_OPTS という
# 環境変数で渡す。$2 を見ていると型の指定が黙って無視される。
PKG=$1
TYPE=${2:-${VERIFY_OPTS:-emacs30nox}}
TYPE=${TYPE:-emacs30nox}
TREE=${TREE:-/usr/pkgsrc}
LOGDIR=${LOGDIR:-/tmp}

[ -d "$TREE/$PKG" ] || { echo "FAIL: $TREE/$PKG が無い"; exit 1; }

MKARGS=""
[ -z "${BINPKG_SITES:-}" ] ||
	MKARGS="DEPENDS_TARGET=bin-install BINPKG_SITES=$BINPKG_SITES"

# 木ぜんぶの既定を決めておく。package 側で EMACS_TYPE を渡すだけだと、
# 依存が別の版で建ってしまう。
grep -q '^EMACS_TYPE' /etc/mk.conf 2>/dev/null ||
	printf 'EMACS_TYPE=\t%s\n' "$TYPE" >> /etc/mk.conf

case $TYPE in
emacs30nox) EMACS_PKG=editors/emacs30-nox11; EMACS_GLOB='emacs30-nox11-*' ;;
emacs31nox) EMACS_PKG=editors/emacs31-nox11; EMACS_GLOB='emacs31-nox11-*' ;;
emacs29nox) EMACS_PKG=editors/emacs29-nox11; EMACS_GLOB='emacs29-nox11-*' ;;
# 古い二つは木に無く、zakinko/ の fork から入れる。verify-elisp17.sh が
# 同じ二つを使っている。ACCEPTED に emacs20/emacs21 を残している package
# は、その版で本当に建つかをここで見る。
emacs20)    EMACS_PKG=zakinko/emacs20;       EMACS_GLOB='emacs20-*' ;;
emacs21nox) EMACS_PKG=zakinko/emacs21-nox11; EMACS_GLOB='emacs21-nox11-*' ;;
*) echo "FAIL: $TYPE の入れ方を知らない"; exit 1 ;;
esac

echo "=== $TYPE を入れる ==="
if ! pkg_info -qe "$EMACS_GLOB"; then
	( cd "$TREE/$EMACS_PKG" && make $MKARGS bin-install ) > "$LOGDIR/emacs.log" 2>&1 ||
	( cd "$TREE/$EMACS_PKG" && make $MKARGS install ) >> "$LOGDIR/emacs.log" 2>&1 ||
		{ tail -20 "$LOGDIR/emacs.log"; echo "FAIL: $EMACS_PKG が入らない"; exit 1; }
fi
pkg_info -e "$EMACS_GLOB"

# PLIST の中の ${...} が本当に定義されるかを先に見る。定義されないものは
# 展開されず literal で残り、build は通って install の段で落ちる。
echo "=== PLIST の変数を見る ==="
sh "$(dirname "$0")/check-plist-vars.sh" "$TREE" "$PKG" || exit 1

# 建てる前に、実際に何が呼ばれるかを出しておく。手元で el を直接
# byte-compile して「通った」と言っても、上流が駆動 file を挟んで
# いれば別物を測っている。log に残しておけば次から同じ形で測れる。
sh "$(dirname "$0")/show-build-entry.sh" "$TREE" "$PKG" || true

echo "=== $PKG を建てる ==="
sh "$(dirname "$0")/verify-pkg.sh" "$PKG" || exit 1

# ここまでで「建って入って外せる」までが済んでいる。それでも使えないことが
# ある。2026-09-23 に四つのうち三つがそうだった (run-elisp.sh の頭に列挙)。
# verify-pkg.sh は外して終わるので、入れ直してから走らせ、また外す。木は
# 建ててあるので入れ直しは速い。verify-pkg.sh は共有なので触らない。
echo "=== $PKG を実際に走らせる ==="
( cd "$TREE/$PKG" && make $MKARGS install ) > "$LOGDIR/reinstall.log" 2>&1 || {
	tail -20 "$LOGDIR/reinstall.log"
	echo "FAIL: $PKG を入れ直せない"; exit 1; }

EMACS_BIN=$(cd "$TREE/$PKG" && make show-var VARNAME=EMACS_BIN 2>/dev/null)
[ -n "$EMACS_BIN" ] || { echo "FAIL: EMACS_BIN が引けない"; exit 1; }

# lisp の置き場は渡さない。run-elisp.sh が pkg_info に訊いて、el を持つ
# directory を全部 load-path へ入れる。**ここで組み立ててはいけない。**
# ${EMACS_LISPPREFIX}/<package 名> は当たらない: emacs-ilisp は ilisp/、
# tamago は egg/ で、tamago はさらに egg/its/ と egg/egg/ に分かれている。
rc=0
sh "$(dirname "$0")/run-elisp.sh" "$PKG" "$EMACS_BIN" || rc=1

( cd "$TREE/$PKG" && make deinstall ) > /dev/null 2>&1 ||
	pkg_delete "${PKG##*/}" > /dev/null 2>&1 || true

[ $rc -eq 0 ] || { echo "FAIL: $PKG は入るが動かない"; exit 1; }
echo "=== 動いた: $PKG ($TYPE) ==="
