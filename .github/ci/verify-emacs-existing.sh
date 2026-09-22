#!/bin/sh
# 木に既に在る elisp package への当て物 (branch emacs-patches) と更新
# (branch emacs-updates) を、素の箱の pkgsrc に当てて建て、主 feature を
# load する。
#
#   VERIFY_OPTS="30" sh verify-emacs-existing.sh zakinko/emacs-diffs
#   VERIFY_OPTS="20 devel/apel misc/lookup" ...     この二つだけ
#
# run-in-qemu.sh が zakinko/emacs-diffs を /usr/pkgsrc/zakinko/emacs-diffs
# に置いてくる。中身は workflow が二つの branch から取り出した
# emacs-patches/*.diff と emacs-updates/*.diff、emacs-updates/new/ の
# 新規 package、そして emacs-existing.txt (package  flavour  feature)。
#
# flavour は VERIFY_OPTS の先頭。
#   30   emacs30-nox11。BINPKG_SITES から bin-install (無ければ建てる)
#   20   emacs20。木から建てる (当て物入り。一時間ほど)
#   x    xemacs-nox11 21.4.25 と xemacs-packages。同じく建てる
#
# 手元 (techne, NetBSD 11.0/amd64) では 76 個を建てて load してある。
# ここは別の arch と版で同じことを測るためのもので、i386 と、9.4/10.1 の
# 古い base で初めて出る物を拾う。
#
# 一つ転けても残りは続ける。最後に数を言い、一つでも落ちたら非零。
set -u
FLAVOUR=${VERIFY_OPTS%% *}; FLAVOUR=${FLAVOUR:-30}
# packages 入力が空でも workflow は "30 " と末尾に空白を付けて渡すので、
# 空白だけの ONLY は空にする。そうしないと case が何にも合わず全部飛ばす
# (run 35697141167 は 54 本当てて 0 個建てた)。
ONLY=$(echo ${VERIFY_OPTS#$FLAVOUR})
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
SRC=$TREE/zakinko/emacs-diffs
LOG=/var/tmp/emacs-existing
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
export PATH
unset PKG_PATH
mkdir -p $LOG

case $FLAVOUR in
30) EMACS_TYPE=emacs30nox;   EMACS_PKG=editors/emacs30-nox11; EMACS=$PREFIX/bin/emacs ;;
20) EMACS_TYPE=emacs20;      EMACS_PKG=editors/emacs20;       EMACS=$PREFIX/bin/emacs ;;
x)  EMACS_TYPE=xemacs214nox; EMACS_PKG=editors/xemacs-nox11;  EMACS=$PREFIX/bin/xemacs ;;
*)  echo "flavour は 30, 20, x のどれか"; exit 1 ;;
esac
# 当て物が当たらないと patch が stdin で聞き続けるので、pkgsrc には
# --batch を渡させ、こちらの patch にも -f と </dev/null を付ける。
BATCH=1; export BATCH
MKARGS="EMACS_TYPE=$EMACS_TYPE"
[ -z "${BINPKG_SITES:-}" ] || MKARGS="$MKARGS DEPENDS_TARGET=bin-install BINPKG_SITES=$BINPKG_SITES"
echo "--- $(uname -s) $(uname -r) / $(uname -m) / flavour $FLAVOUR ---"

# 5 分ごとに log の末尾を出す。無音のまま timeout に当たると何も残らない。
tick() {
	_log=$1; _n=0
	while [ $_n -lt 80 ]; do
		sleep 300; _n=$((_n+1)); [ -f "$_log" ] || continue
		echo "      [$(date +%H:%M)] $(wc -l < "$_log" | tr -d ' ') 行: $(tail -1 "$_log" | cut -c1-90)" || exit 0
	done
}
# build を log へ流して走らせる。$1 が log、残りが命令。
runlog() {
	_l=$1; shift; : > "$_l"; tick "$_l" & _t=$!
	"$@" < /dev/null > "$_l" 2>&1; _rc=$?
	kill $_t 2>/dev/null; return $_rc
}

echo "=== 当て物を当てる ==="
bad=0
for d in $SRC/emacs-patches/*.diff $SRC/emacs-updates/*.diff; do
	[ -f "$d" ] || continue
	# NetBSD の patch は既定で .orig を残す。patches/ に落ちると pkgsrc が
	# それを当て物として拾い "invalid checksum" で止まる (run 35700632415 の
	# math/ess)。-V none で backup を作らせない。
	if patch -V none -d "$TREE" -p0 -N -f -s < "$d" > $LOG/patch.out 2>&1; then
		printf 'ok  %s\n' "$(basename "$d")"
	else
		printf 'NG  %s\n' "$(basename "$d")"; sed 's/^/      /' $LOG/patch.out | head -8; bad=$((bad+1))
	fi
done
for n in "$SRC"/emacs-updates/new/*/; do
	[ -d "$n" ] || continue
	p=$(basename "$n"); c=$(sed -n 's/^CATEGORIES=[[:space:]]*\([^[:space:]]*\).*/\1/p' "$n/Makefile" | head -1)
	rm -rf "$TREE/$c/$p"; cp -R "$n" "$TREE/$c/$p"; printf 'new %s/%s\n' "$c" "$p"
done
[ $bad -eq 0 ] || { echo "FAIL: $bad 本が当たらない"; exit 1; }
# 念のため、残った剥がし跡を掃く。
find "$TREE" -name '*.orig' -path '*/patches/*' -delete 2>/dev/null

echo "=== $EMACS_PKG を入れる ==="
grep -q '^EMACS_TYPE' /etc/mk.conf 2>/dev/null || printf 'EMACS_TYPE=\t%s\n' "$EMACS_TYPE" >> /etc/mk.conf
if ! ( cd "$TREE/$EMACS_PKG" && make $MKARGS show-var VARNAME=PKGNAME | xargs -I{} pkg_info -qe '{}' ); then
	rc=1
	[ "$FLAVOUR" = 30 ] && [ -n "${BINPKG_SITES:-}" ] &&
		{ runlog $LOG/emacs.log sh -c "cd $TREE/$EMACS_PKG && make $MKARGS bin-install" && rc=0; }
	[ $rc -eq 0 ] || runlog $LOG/emacs.log sh -c "cd $TREE/$EMACS_PKG && make $MKARGS package-install" || {
		tail -40 $LOG/emacs.log; echo "FAIL: $EMACS_PKG が入らない"; exit 1; }
fi
echo "    $($EMACS --version 2>&1 | head -1)"
if [ "$FLAVOUR" = x ]; then
	# apel や riece は xemacs-packages の上に建つ。
	runlog $LOG/xemacs-packages.log sh -c "cd $TREE/editors/xemacs-packages && make $MKARGS package-install" ||
		{ tail -20 $LOG/xemacs-packages.log; echo "FAIL: xemacs-packages が入らない"; exit 1; }
fi

echo "=== 建てて load する ==="
ok=0; ng=0; skip=0; : > $LOG/failed
# 一覧は fd 3 から読む。loop の中の make や emacs に stdin を食われない。
while read -r p f feat extra <&3; do
	[ "$f" = "$FLAVOUR" ] || continue
	[ -z "$ONLY" ] || case " $ONLY " in *" $p "*) ;; *) continue ;; esac
	d=$TREE/$p; n=$(echo "$p" | tr / _)
	[ -d "$d" ] || { echo "  --- $p  ★ 木に無い"; skip=$((skip+1)); continue; }
	acc=$(cd "$d" && make $MKARGS show-var VARNAME=EMACS_VERSIONS_ACCEPTED 2>/dev/null)
	case " $acc " in *" $EMACS_TYPE "*|"  ") ;; *) echo "  --- $p  受け付けない ($acc)"; skip=$((skip+1)); continue ;; esac
	printf '  --- %-32s ' "$p"
	( cd "$d" && make $MKARGS clean ) > /dev/null 2>&1
	if ! runlog $LOG/$n.log sh -c "cd $d && make $MKARGS $extra package-install"; then
		echo "★ 建たない"; tail -15 $LOG/$n.log | sed 's/^/        /'; ng=$((ng+1)); echo "$p" >> $LOG/failed
		( cd "$d" && make $MKARGS clean ) > /dev/null 2>&1; continue
	fi
	( cd "$d" && make $MKARGS clean ) > /dev/null 2>&1
	w=$(grep -c '^Warning:\|^In .*:$' $LOG/$n.log 2>/dev/null || echo 0)
	l=$($EMACS -batch -q --no-site-file -eval "(progn (require (quote $feat)) (princ (format \"load-ok %s\" (featurep (quote $feat)))))" < /dev/null 2>&1 | tr -c '[:print:]\n' '?' | tail -3 | tr '\n' ' ')
	case "$l" in
	*"load-ok t"*) echo "ok (byte-compile の警告 $w)"; ok=$((ok+1)) ;;
	*) echo "★ 建ったが load できない: $l" | cut -c1-200; ng=$((ng+1)); echo "$p" >> $LOG/failed ;;
	esac
done 3< "$SRC/emacs-existing.txt"
echo "=== flavour $FLAVOUR: 通った $ok / 転けた $ng / 飛ばした $skip ==="
[ $ng -eq 0 ] || { echo "--- 転けたもの ---"; cat $LOG/failed; exit 1; }
