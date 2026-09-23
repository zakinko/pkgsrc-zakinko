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
*) echo "FAIL: $TYPE の入れ方を知らない"; exit 1 ;;
esac

echo "=== $TYPE を入れる ==="
if ! pkg_info -qe "$EMACS_GLOB"; then
	( cd "$TREE/$EMACS_PKG" && make $MKARGS bin-install ) > "$LOGDIR/emacs.log" 2>&1 ||
	( cd "$TREE/$EMACS_PKG" && make $MKARGS install ) >> "$LOGDIR/emacs.log" 2>&1 ||
		{ tail -20 "$LOGDIR/emacs.log"; echo "FAIL: $EMACS_PKG が入らない"; exit 1; }
fi
pkg_info -e "$EMACS_GLOB"

echo "=== $PKG を建てる ==="
sh "$(dirname "$0")/verify-pkg.sh" "$PKG"
