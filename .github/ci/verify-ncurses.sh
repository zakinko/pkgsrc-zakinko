#!/bin/sh
# devel/ncurses の configure が OpenBSD で /var/run/ld.so.hints を潰す件の
# 対照を、一本の job で両向きに取る。
#
#   当て物あり -> hints に /usr/local/lib が残る
#   当て物なし -> hints が /usr/lib だけになる (bug が再現する)
#   当て物あり -> もう一度残る (一度目が偶然でないこと)
#
# 三段目まで見るのは、二段目で箱を壊すからで、壊したまま抜けると
# vmactions の copyback の rsync が library を見失って job が赤くなる。
# どこで抜けても貼り直すように trap を置いてある。
#
# configure が辿り着く答え自体は当て物の有無で変わらない。それも
# config.log から出して並べる。変えているのは probe の副作用だけで、
# ncurses の建ち方ではない、というのがこの当て物の言い分なので。
set -e
PKGDIR=${1:-devel/ncurses}
TREE=${TREE:-/usr/pkgsrc}
PREFIX=${PREFIX:-/usr/pkg}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin:/usr/local/bin
export PATH
D=$TREE/$PKGDIR
M=$D/Makefile
W=/var/tmp/ncurses-ldconfig-check
rc=0

if [ "$(uname -s)" != OpenBSD ]; then
	echo "  OpenBSD ではないので ld.so.hints の検査はしない ($(uname -s))"
	exit 0
fi

mkdir -p "$W"

# rc(8) が起動時に渡すのと同じ一覧。壊れたときはこれで戻る。
RCDIRS="/usr/local/lib /usr/X11R6/lib"
repair() {
	ldconfig $RCDIRS 2>&1 | sed 's/^/  ldconfig: /' || true
}
restore_makefile() {
	[ -f "$W/Makefile.patched" ] && cp "$W/Makefile.patched" "$M"
	repair
}
trap 'restore_makefile' EXIT INT TERM

sd() {	# 今の hints の探索 directory を一行で
	ldconfig -r 2>/dev/null |
		sed -n 's/^[[:space:]]*search directories:[[:space:]]*//p'
}
answer() {	# configure が辿り着いた探索 path
	# config.log の cache 変数では測れない。当て物ありのときは環境から
	# 渡っているので cache に載らず、両方とも空で出てきてしまう
	# (run 35708242316 で実際にそうなった)。configure 自身が印字する
	# "checking for linker search path... " を読む。
	sed -n 's/.*checking for linker search path\.*[[:space:]]*//p' "$1" |
		tail -1
}

if [ -x "$PREFIX/bin/bmake" ]; then PKGMAKE="$PREFIX/bin/bmake"
else PKGMAKE=bmake; fi

grep -q 'cf_cv_ld_searchpath' "$M" || {
	echo "!! $M に当て物が入っていない。TREE_PATCH を通したか" >&2
	exit 1; }
cp "$M" "$W/Makefile.patched"

# ------------------------------------------------------------------
# 何より先に、触っていない状態を読む。以前はここが無く、一段目の頭で
# repair を走らせてから読んでいたので、四行とも「こちらが並べた順」に
# なっていた。rc が起動時に作る順とは違う (peer の 7.9/arm64 の箱では
# 素が /usr/lib:/usr/X11R6/lib:/usr/local/lib で、X11R6 が先)。素を
# 読まないと、報告に書いた並びが箱の性質ではなくこちらの repair の
# 引数の順になる。
STOCK=$(sd)
echo "########## 零段目: 触っていない状態 ##########"
echo "  search directories: $STOCK"

echo "########## 一段目: 当て物ありで configure ##########"
repair					# 既知の状態から始める
( cd "$D" && $PKGMAKE clean > /dev/null 2>&1 || true )
( cd "$D" && $PKGMAKE configure > "$W/with.log" 2>&1 ) || {
	echo "!! 当て物ありで configure が落ちた"; tail -20 "$W/with.log"; rc=1; }
WITH=$(sd)
echo "  search directories: $WITH"
echo "  configure の答え  : $(answer "$W/with.log")"

# ------------------------------------------------------------------
echo "########## 二段目: 当て物を剥がして configure (bug の再現) ##########"
grep -v 'cf_cv_ld_searchpath' "$W/Makefile.patched" > "$W/Makefile.stock"
cp "$W/Makefile.stock" "$M"
if grep -q 'cf_cv_ld_searchpath' "$M"; then echo "!! 剥がせていない"; rc=1; fi
repair					# 壊れる前を揃える
BEFORE=$(sd)
echo "  configure の前: $BEFORE"
( cd "$D" && $PKGMAKE clean > /dev/null 2>&1 || true )
( cd "$D" && $PKGMAKE configure > "$W/without.log" 2>&1 ) ||
	echo "  (当て物なしの configure が落ちた。hints は下で見る)"
WITHOUT=$(sd)
echo "  configure の後: $WITHOUT"
echo "  configure の答え  : $(answer "$W/without.log")"
cp "$W/Makefile.patched" "$M"		# すぐ戻す

# ------------------------------------------------------------------
echo "########## 三段目: 当て物を戻して configure ##########"
repair
( cd "$D" && $PKGMAKE clean > /dev/null 2>&1 || true )
( cd "$D" && $PKGMAKE configure > "$W/again.log" 2>&1 ) || {
	echo "!! 戻した後の configure が落ちた"; tail -20 "$W/again.log"; rc=1; }
AGAIN=$(sd)
echo "  search directories: $AGAIN"
echo "  configure の答え  : $(answer "$W/again.log")"

# ------------------------------------------------------------------
echo
echo "########## まとめ ##########"
printf '  %-14s %s\n' "素の状態:"   "$STOCK"
printf '  %-14s %s\n' "当て物あり:" "$WITH"
printf '  %-14s %s\n' "剥がす前:"   "$BEFORE"
printf '  %-14s %s\n' "剥がした後:" "$WITHOUT"
printf '  %-14s %s\n' "戻した後:"   "$AGAIN"

ok() { case $1 in */usr/local/lib*) return 0 ;; *) return 1 ;; esac; }

ok "$STOCK" || { echo "  !! 素の状態で既に /usr/local/lib が無い。この箱では"
                 echo "     測れない (壊れる前と後が同じ顔になる)"; rc=1; }
ok "$WITH"  || { echo "  !! 当て物ありなのに /usr/local/lib が消えた"; rc=1; }
ok "$AGAIN" || { echo "  !! 戻した後に /usr/local/lib が消えた"; rc=1; }
if ok "$WITHOUT"; then
	echo "  !! 当て物を剥がしても hints が壊れない。この箱では bug が"
	echo "     再現していないので、当て物の効き目を測れていない"
	rc=1
else
	echo "  剥がすと hints が「$WITHOUT」だけになる (bug 再現)"
fi

echo
if [ $rc = 0 ]; then
	echo "== ncurses: 当て物が ld.so.hints を守っている ($(uname -sr) $(uname -m))"
else
	echo "== ncurses: FAILURES on $(uname -sr) $(uname -m)"
fi
exit $rc
