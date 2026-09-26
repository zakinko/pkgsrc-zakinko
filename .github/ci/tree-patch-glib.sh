#!/bin/sh
# devel/glib2 の patch-glib_glib-unix.c を、DragonFly を F_GETPATH の枝へ移した
# 版に差し替える。pkgsrc へ送る当て物そのもので、ここで DragonFly に glib2 と
# その先の polkit を建てさせて測る。
#
# TREE_PATCH の口は bootstrap の前に走る。distinfo の SHA1 は patch-sha1.sh が
# digest に頼らず base の道具で出す。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
CI=$(cd "$(dirname "$0")" && pwd)
. "$CI/patch-sha1.sh"
d=$TREE/devel/glib2
n=patch-glib_glib-unix.c
[ -f "$d/patches/$n" ] || { echo "!! $d/patches/$n が無い" >&2; exit 1; }
cp "$CI/tree-patches/$n" "$d/patches/$n"
h=$(patch_sha1 "$d/patches/$n")
awk -v n="$n" -v h="$h" '$0 ~ "^SHA1 \\(" n "\\) = " { print "SHA1 (" n ") = " h; next } { print }' \
	"$d/distinfo" > "$d/distinfo.new" && mv "$d/distinfo.new" "$d/distinfo"
grep -q "SHA1 ($n) = $h" "$d/distinfo" || { echo "!! distinfo が書けていない" >&2; exit 1; }
grep -q 'defined (__DragonFly__)' "$d/patches/$n" || { echo "!! 差し替わっていない" >&2; exit 1; }
echo "  glib2: $n を DragonFly 対応の版に差し替えた ($h)"
