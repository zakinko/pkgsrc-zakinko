#!/bin/sh
# emacs-new/ の生成 package を、その箱で片端から組む。
#
#   sh verify-emacs-new.sh zakinko/emacs-new
#
# run-in-qemu.sh が emacs-new を /usr/pkgsrc/zakinko/emacs-new に置いて
# くる。package は互いを ../../devel/<pkg> で指すので、zakinko/ の下では
# なく本物の devel/ と editors/ に写してから組む。順序は generator が
# 依存で並べた order.txt。emacs30-nox11 は BINPKG_SITES から bin-install
# で引く。
#
# 見るのは「組めて入る」まで。落ちた package は名前と log の末尾を出し、
# 最後に数を言う。一つでも落ちたら非零。手元 (techne) で 408 個通した
# ものを、素の 11.0 の箱でもう一度測るのが目的で、依存が pkgsrc-2026Q2
# の木に無い (emacs-updates 側の更新が要る) ものはここで初めて分かる。
#
#   VERIFY_OPTS="devel/a-el editors/avy-el"   これだけ組む (空なら全部)

set -e
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
SRC=$TREE/zakinko/emacs-new
LOGDIR=/var/tmp/emacs-new
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
export PATH
unset PKG_PATH
mkdir -p $LOGDIR

MKARGS=
[ -z "${BINPKG_SITES:-}" ] || MKARGS="DEPENDS_TARGET=bin-install BINPKG_SITES=$BINPKG_SITES"
echo "--- $(uname -s) $(uname -r) / $(uname -m) / $(ls $SRC/devel $SRC/editors | grep -c .) packages ---"

echo "--- 木へ写す ---"
for c in devel editors; do
	for d in "$SRC"/$c/*/; do
		p=$(basename "$d"); rm -rf "$TREE/$c/$p"; cp -R "$d" "$TREE/$c/$p"
	done
done

echo "--- emacs30-nox11 ---"
grep -q '^EMACS_TYPE' /etc/mk.conf 2>/dev/null || printf 'EMACS_TYPE=\temacs30nox\n' >> /etc/mk.conf
if ! pkg_info -qe 'emacs30-nox11-*'; then
	( cd "$TREE/editors/emacs30-nox11" && make $MKARGS bin-install ) > $LOGDIR/emacs30.log 2>&1 ||
		( cd "$TREE/editors/emacs30-nox11" && make $MKARGS install ) >> $LOGDIR/emacs30.log 2>&1 ||
		{ tail -20 $LOGDIR/emacs30.log; echo "FAIL: emacs30-nox11 が入らない"; exit 1; }
fi
pkg_info -e 'emacs30-nox11-*'

LIST=${VERIFY_OPTS:-$(cat "$SRC/generator/order.txt")}
ok=0; bad=0; : > $LOGDIR/failed
for p in $LIST; do
	[ -d "$TREE/$p" ] || { echo "?? $p: no such directory"; continue; }
	if ( cd "$TREE/$p" && make $MKARGS install > $LOGDIR/one.log 2>&1 && make clean > /dev/null 2>&1 ); then
		ok=$((ok+1)); printf 'OK  %s\n' "$p"
	else
		bad=$((bad+1)); printf 'NG  %s\n' "$p"; echo "$p" >> $LOGDIR/failed
		grep -E 'Error|error:|ERROR|Cannot open' $LOGDIR/one.log | head -3 | sed 's/^/      /'
		( cd "$TREE/$p" && make clean > /dev/null 2>&1 ) || true
	fi
done
echo "=== $ok 個が入り、$bad 個が落ちた ==="
[ $bad -eq 0 ] || { echo "--- 落ちたもの ---"; cat $LOGDIR/failed; exit 1; }
