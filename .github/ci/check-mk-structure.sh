#!/bin/sh
# pkgsrc の Makefile を、bmake が読む前に構造だけ数える。二つ見る。
#
#   (1) bsd.prefs.mk より前に OPSYS / OS_VARIANT などを条件に使っていないか
#   (2) target の recipe の途中に変数代入を挟んでいないか
#
# どちらも同じ日に踏んだ。当て物は手元で当たり、検査も通り、素の木にも当たる。
# それでも bmake が読めない形になっていて、macOS を二度落とした。当たることと
# 読めることは別。
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

# 自己試験はここではやらない。一度この script の中で自分を再帰呼び出しする
# 形にしたら、環境変数が子に引き継がれて無限再帰し、fork が尽きた。呼ぶ側が
# 素の写しに対して一度、当てた後に一度、合わせて二度呼ぶ。検査は一つの file
# だけを見る。
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

# ------------------------------------------------------------------
# (2) recipe の途中の変数代入。
#
# make は target 行のあとの tab 始まりの行を recipe として繋ぐ。その途中に
# 桁 0 の変数代入を置くと recipe が切れ、続く tab の行が
#
#	bmake: Unassociated shell command "for f in ..."
#	in .for loop from Makefile:266 with lib = lib
#
# になる。CHECK_SHLIBS_SKIP+= を fix-darwin-install-name の recipe の中に
# 置いてこれを出した。.for や .if は target を作らないので、代入の後に
# target 行を挟まずに tab の行が来たら、それは切れている。
# bmake の規則で数える。tab で始まる行 (recipe) は、直前の桁 0 の変数代入より
# 後に target 行が無ければ target に繋がっていない。最初 "target を見た後の
# 代入" で数えたら、素の木の EXTRACT_SUFX や TOOL_DEPENDS まで告発した。
# 一度 target を見たら旗が下りない書き方だったので、直した版まで落ちた。
# 旗は代入で下ろし、target 行で上げる。
bad2=$(awk '
	# 行末の \\ で続く行は、前の論理行の一部。代入の継続行は tab で始まる
	# ことが在るので、recipe と数えてはいけない。素の木の GENERATE_PLIST+=
	# がまさにそれで、これを数えていなかったので上流の Makefile まで
	# 告発していた。
	cont { if ($0 !~ /\\$/) cont = 0; next }
	# target 行。桁 0 で、空白・# ・. で始まらず、= より前に : が在る。
	# .PHONY: は . で始まるので target とは数えない (実体が後に来る)。
	/^[^ \t#.]/ {
		line = $0
		if (line ~ /\\$/) cont = 1
		eq = index(line, "=")
		co = index(line, ":")
		if (co > 0 && (eq == 0 || co < eq)) { have = 1; next }
		if (eq > 0) { have = 0; lastassign = NR ": " line; next }
		next
	}
	/^\t/ { if (!have && lastassign != "") { print lastassign; lastassign = "" } }
' "$M")

if [ -n "$bad2" ]; then
	echo "!! 変数代入のあとに、target に繋がらない recipe の行が在る:" >&2
	printf '%s\n' "$bad2" | sed 's/^/   代入: /' >&2
	echo "   bmake が Unassociated shell command で止まる。" >&2
	echo "   代入は target 定義より前へ動かす。" >&2
	exit 1
fi
echo "  recipe の途中の変数代入: 0 件"
