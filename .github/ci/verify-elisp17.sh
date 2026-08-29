#!/bin/sh
# 上流 pkgsrc から引き取った 17 個を、emacs20 か emacs21 の上で建てる。
#
#   VERIFY_OPTS=20 sh verify-elisp17.sh 'zakinko/emacs20 zakinko/emacs ...'
#
# 版は VERIFY_OPTS で受ける。run-in-qemu.sh がゲストへ運ぶ環境変数は명示の
# 一覧で決まっていて、そこに在るのがこれだから。EMACS_V でも受ける (手で
# 走らせるとき用)。
#
# これらは emacs20 か emacs21 が入っていないと fetch すら通らない。
#
#	ERROR: Accepted versions are: emacs21 emacs21nox emacs20
#	ERROR: No valid Emacs version installed found
#
# techne は EMACS_TYPE=emacs30nox で、入れ替えると elisp を建てている他の
# セッションが全部止まる。だから使い捨ての VM で建てる。
#
# 先に emacs を建てて入れ、そのあと 17 個を順に建てる。一つ転けても残りは
# 続ける。何が通って何が転けたかが要るので、途中で止めない。

set -u

EMACS_V=${EMACS_V:-${VERIFY_OPTS:-20}}
OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
HERE=$(cd "$(dirname "$0")" && pwd)

PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
PATH=$PATH:/usr/X11R7/bin:/usr/X11R6/bin:/usr/local/bin
export PATH
unset PKG_PATH

case $EMACS_V in
20) EMACS_TYPE=emacs20;   EMACS_PKG=zakinko/emacs20 ;;
21) EMACS_TYPE=emacs21nox; EMACS_PKG=zakinko/emacs21-nox11 ;;
*)  echo "EMACS_V は 20 か 21"; exit 1 ;;
esac
export EMACS_TYPE

PKGMAKE="make"
MKARGS="EMACS_TYPE=$EMACS_TYPE"
[ -n "${BINPKG_SITES:-}" ] && MKARGS="$MKARGS DEPENDS_TARGET=bin-install BINPKG_SITES=$BINPKG_SITES"

echo "=== emacs$EMACS_V を建てて入れる ($OS $(uname -r) / $(uname -m)) ==="
cd "$TREE/$EMACS_PKG" || { echo "FAIL: $EMACS_PKG が無い"; exit 1; }
if ! $PKGMAKE $MKARGS package-install > /tmp/emacs$EMACS_V.log 2>&1; then
	tail -40 /tmp/emacs$EMACS_V.log
	echo "FAIL: emacs$EMACS_V が入らない"
	exit 1
fi
echo "    $($PREFIX/bin/emacs --version 2>&1 | head -1)"

# 17 個。emacs20 でしか建たないもの、21 でしか建たないものがあるので、
# 受け付けない組み合わせは飛ばす。飛ばしたことは出す。
LIST_20="zakinko/leim20 zakinko/pcl-cvs zakinko/mule-ucs zakinko/tamago
	 zakinko/iiimecf zakinko/calc zakinko/emacs-ilisp zakinko/w3
	 devel/emacs20-elib"
LIST_21="zakinko/leim21 zakinko/mule-ucs zakinko/tamago zakinko/iiimecf
	 zakinko/calc zakinko/nxml-mode zakinko/emacs-ilisp zakinko/jde
	 zakinko/w3 misc/bbdb2 www/emacs-w3m"

eval "LIST=\$LIST_$EMACS_V"

ok=0; ng=0; skip=0
for p in $LIST; do
	d=$TREE/$p
	[ -d "$d" ] || { echo "  --- $p  ★ ツリーに無い"; skip=$((skip+1)); continue; }
	acc=$(cd "$d" && $PKGMAKE $MKARGS show-var VARNAME=EMACS_VERSIONS_ACCEPTED 2>/dev/null)
	case " $acc " in
	*" $EMACS_TYPE "*|"  ") : ;;
	*) echo "  --- $p  受け付けない ($acc)"; skip=$((skip+1)); continue ;;
	esac
	printf "  --- %-24s " "$p"
	( cd "$d" && $PKGMAKE $MKARGS clean ) > /dev/null 2>&1
	if ( cd "$d" && $PKGMAKE $MKARGS package-install ) > "/tmp/$(basename $p).log" 2>&1; then
		# byte-compile の警告を数える。当て物で .el を書き換えたなら、
		# 増えていないことまで見ないと「通った」と言えない。当て物が
		# 触った file の名前を含む行は、数だけでなく中身も出す。
		w=$(grep -c '^Warning:\|^In .*:$' "/tmp/$(basename $p).log" 2>/dev/null || echo 0)
		echo "ok (byte-compile の警告 $w)"
		if [ -d "$d/patches" ]; then
			for pf in "$d"/patches/patch-*; do
				[ -f "$pf" ] || continue
				el=$(sed -n 's|^--- \(.*\.el\)\.orig.*|\1|p' "$pf" | head -1)
				[ -n "$el" ] || continue
				grep -F "$(basename "$el")" "/tmp/$(basename $p).log" 2>/dev/null \
				  | grep -i 'warning' | head -6 | sed 's/^/        /'
			done
		fi
		ok=$((ok+1))
	else
		echo "★ 転けた"
		tail -20 "/tmp/$(basename $p).log" | sed 's/^/        /'
		ng=$((ng+1))
	fi
done

echo "=== emacs$EMACS_V: 通った $ok / 転けた $ng / 飛ばした $skip ==="

# site-start.d が効いているか。calc が入ったときだけ見る。
if [ -f "$PREFIX/share/emacs/site-lisp/site-start.d/20-calc.el" ]; then
	echo "--- site-start.d が効くか ---"
	if "$PREFIX/bin/emacs" --batch --no-init-file \
	     --eval '(kill-emacs (if (commandp (quote calc-dispatch)) 0 1))' 2>/dev/null
	then echo "    calc-dispatch が autoload 済み"
	else echo "    ★ calc-dispatch が居ない"; ng=$((ng+1)); fi
fi

[ "$ng" = 0 ] || exit 1
