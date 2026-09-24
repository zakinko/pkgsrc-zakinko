#!/bin/sh
# pkgsrc の Makefile で、bsd.prefs.mk より前に OPSYS / OS_VARIANT /
# MACHINE_PLATFORM を条件に使っていないか数える。
#
# これらは bsd.prefs.mk が定義する。それより前で .if に使うと bmake が
#
#	Malformed conditional '${OPSYS} == "Darwin"'
#
# で止まる。同じ型を二度踏んだ。一度目は OS_VARIANT を非 SunOS の箱で使って
# 未定義だったもので、:U を付けて直した。二度目は OPSYS を 46 行目に置いた
# もので、bsd.prefs.mk は 61 行目だった。**:U では直らない** — 常に空になって
# 条件が偽になり、置いたはずの手当てが黙って効かなくなる。位置を直すしかない。
#
# 「気を付ける」では止まらなかったので数える側に置く。
set -e
M=${1:?usage: $0 <Makefile>}
VARS='OPSYS|OS_VARIANT|MACHINE_PLATFORM|MACHINE_ARCH|OS_VERSION'

prefs=$(grep -n 'include.*mk/bsd\.prefs\.mk' "$M" | head -1 | cut -d: -f1)
if [ -z "$prefs" ]; then
	# prefs を include しない package も在る。その場合は bsd.pkg.mk が
	# 末尾で読むので、条件に使えるのは .include の後だけ。ここでは
	# 判定材料が無いので何も言わない。
	echo "  (bsd.prefs.mk を include していないので位置は測れない)"
	exit 0
fi

bad=$(awk -v p="$prefs" -v v="$VARS" '
	NR < p && /^\.[[:space:]]*(el)?if/ && $0 ~ "\\$\\{(" v ")" { print NR ": " $0 }
' "$M")

if [ -n "$bad" ]; then
	echo "!! bsd.prefs.mk ($prefs 行) より前で条件に使っている:" >&2
	printf '%s\n' "$bad" | sed 's/^/   /' >&2
	echo "   bmake は Malformed conditional で止まる。:U では直らない" >&2
	echo "   (常に偽になって手当てが黙って効かなくなる)。位置を動かす。" >&2
	exit 1
fi
echo "  bsd.prefs.mk ($prefs 行) より前の条件使用: 0 件"
