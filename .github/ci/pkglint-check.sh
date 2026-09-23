#!/bin/sh
# pkglint を一つの package に掛け、error を落とす理由にする。
#
#   sh pkglint-check.sh <pkgdir> [比較する素の dir]
#
# 第二引数を渡すと、そちらにも掛けて「増えた行」だけを出す。行番号は
# 捨てて比べる (当て物で行がずれると元からの WARN が増えたように見える)。
PKG=$1
BASE=$2
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin; export PATH
T=${TMPDIR:-/tmp}
BMAKE=$PREFIX/bin/bmake
[ -x "$BMAKE" ] || BMAKE=make
command -v pkglint > /dev/null 2>&1 || {
	( cd "$TREE/pkgtools/pkglint" && $BMAKE install > "$T/pkglint-install.log" 2>&1 ) || {
		echo "  (pkglint が入らなかった。見ない)"; exit 0; }
}
_strip() { sed 's/^\([A-Z]*: [^:]*\):[0-9]*:/\1:/'; }
( cd "$TREE/$PKG" && pkglint -Wall 2>&1 ) > "$T/pkglint.after" || true
if [ -n "$BASE" ] && [ -d "$TREE/$BASE" ]; then
	( cd "$TREE/$BASE" && pkglint -Wall 2>&1 ) > "$T/pkglint.before" || true
	_strip < "$T/pkglint.before" > "$T/pkglint.before.s"
	_new=$(grep -vE '^Looks fine|^[0-9]+ (warnings|errors)|^$' "$T/pkglint.after" | _strip | grep -vxF -f "$T/pkglint.before.s" || true)
	if [ -n "$_new" ]; then
		echo "  pkglint で増えた行:"; echo "$_new" | sed 's/^/     /'
	else
		echo "  ok pkglint: 素から増えた行は無い"
	fi
else
	grep -vE '^$' "$T/pkglint.after" | head -20 | sed 's/^/     /'
fi
_err=$(grep -c '^ERROR:' "$T/pkglint.after" 2>/dev/null || true)
[ "$_err" = 0 ] || { echo "!! pkglint が ERROR を $_err 件出した"; exit 1; }
exit 0
