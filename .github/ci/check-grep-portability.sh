#!/bin/sh
# -E も -P も付いていない grep の pattern に、POSIX BRE が定めない escape が
# 在ったら落とす。
#
# なぜ機械に置くのか。この罠を注記したコメントが既に木の二箇所に在った
# (verify-thttpd.sh と verify-croc.sh)。つまり誰かが二度踏んで二度その場だけ
# 直している。それでも木の他の八件は残っていた。**コメントは踏んだ場所にしか
# 効かない。**
#
# 何が危ないか。POSIX BRE は \| \s \S \d \w \W \+ \? を定めていない。GNU grep
# は全部解すが、そうでない grep では
#
#   grep -q 'a\|b'   常に偽
#   grep -c 'a\|b'   常に 0
#
# になる。error は出ないので、判定に使っていると黙って反対の答が出る。
# 実際 verify-gdb7.sh の三つの if と verify-elisp17.sh の警告の数え上げが
# この形だった (後者は「警告 0 件」と答え続ける)。
#
# 箱ごとに違う。peer (netbsd-zfs-4c) が techne で実測して、そこでは \| は
# 解されるが \s は解されない。だから「BSD だから \| が駄目」と書くと外れる。
# ここは「どの箱で駄目か」ではなく「どの箱でも正しいのは -E」として見る。
# 直し方が一つに決まるので、箱ごとの差を数える必要が無い。
#
# ただし「どの箱でも正しいのは -E」は**外れる**。Solaris 11.4 の /usr/bin/grep
# には -E そのものが無く、grep: illegal option -- E で落ちる。落ちた exit 1 は
# 「当たらなかった」exit 1 と区別が付かないので、-E に直したことで別の黙った
# 誤答が生まれる。下の第二段がその側を見る。
#
# 箱が実際に何を解すかは別に測る。build-on-bsd.sh が起動時に印字する。
set -e
D=$(cd "$(dirname "$0")" && pwd)
# repo の root。$D は <repo>/.github/ci なので二つ上。最初ここを一つ上
# (= .github) にしておいて、下で "$ROOT/.github" と**もう一度**足していた。
# .github/.github は無いので常に 0 件を返し、「直したあと 0 件」という確認
# 自体が意味の無い 0 だった。木にわざと不良品を置いて落ちることを見るまで
# 気付いていない。この script が防ごうとしている罠そのもの。
ROOT=${1:-$(cd "$D/../.." && pwd)}
G=/usr/bin/grep
[ -x "$G" ] || G=grep

# POSIX BRE が定めない escape を一つの ERE で書く。\\ が literal の backslash、
# 続く bracket の中では | も + も ? も literal。最初これを二つの変数に分けて
# sed で繋ごうとして "grep: empty (sub)expression" で壊し、自己試験に捕まえて
# もらった。組み立てるより一本で書く方が壊れにくい。
BAD='\\[|sSdwW+?]'

scan() {  # $1=対象の木  -> 当たった行を stdout、件数を戻り値では返さない
	find "$1" -type f \( -name '*.sh' -o -name '*.yml' \) -print 2>/dev/null |
	while read -r f; do
		# この script 自身は除く。中の heredoc に、自己試験のための
		# 不良品を**わざと**書いてあるので、除かないと自分を告発して
		# 永久に赤くなる。除くことで生まれる死角は小さい: ここの grep は
		# 全部 $G -E か、escape を含まない pattern で書いてある。
		case ${f##*/} in check-grep-portability.sh) continue ;; esac
		# -E も -P も egrep も付いていない grep の行だけを見る。
		$G -n 'grep' "$f" 2>/dev/null |
		$G -v -E 'grep -[a-zA-Z]*[EP]|egrep' |
		$G -E -- "$BAD" |
		$G -v -E '^[0-9]+:[[:space:]]*#' |
		sed "s|^|$f:|"
	done
}

# ------------------------------------------------------------------
# 自己試験を先頭に置く。既知の不良品を通すなら、この検査は数えていない。
T=$(mktemp -d)
trap 'rm -rf "$T"' 0
mkdir -p "$T/good" "$T/bad"
cat > "$T/bad/a.sh" <<'BAD'
if grep -q 'zutil\|expanded'; then :; fi
w=$(grep -c '^Warning:\|^In ' log)
grep -n 'bla\s\+_C_LABEL' *.S
BAD
cat > "$T/good/a.sh" <<'GOOD'
if grep -qE 'zutil|expanded'; then :; fi
w=$(grep -cE '^Warning:|^In ' log)
grep -nE 'bla[[:space:]]+_C_LABEL' *.S
# BSD の grep は BRE の \| を解さないことがある  <- コメントは拾わない
GOOD
nbad=$(scan "$T/bad" | wc -l | tr -d ' ')
ngood=$(scan "$T/good" | wc -l | tr -d ' ')
echo "自己試験: 既知の不良品 $nbad 件 (3 が正)、直した物 $ngood 件 (0 が正)"
if [ "$nbad" -ne 3 ] || [ "$ngood" -ne 0 ]; then
	echo "!! 検査そのものが壊れている。木は見ない。" >&2
	scan "$T/bad" | sed 's/^/   bad: /' >&2
	scan "$T/good" | sed 's/^/   good: /' >&2
	exit 1
fi

# ------------------------------------------------------------------
echo "対象: $ROOT"
out=$(scan "$ROOT/.github" || true)
n=$(printf '%s' "$out" | $G -c . || true)
[ -n "$n" ] || n=0
if [ "$n" -eq 0 ]; then
	echo "移植性の無い escape を使う grep: 0 件"
else
echo "!! 移植性の無い escape を使う grep が $n 件" >&2
printf '%s\n' "$out" | sed 's/^/   /' >&2
echo >&2
echo "   POSIX BRE は \\| \\s \\S \\d \\w \\W \\+ \\? を定めない。grep -E に" >&2
echo "   直して pattern 側は | と [[:space:]] で書く。ただし SunOS で走る" >&2
echo "   script では -E も使えない。下の第二段を見ること。" >&2
# ここで exit しない。第一段で落とすと第二段が一度も走らず、二つある
# うち片方しか見えないまま直しては撃ち直すことになる。最後にまとめて
# 落とす。
fi

# ==================================================================
# 第二段: SunOS の箱で走る script は -E も使えない。
#
# Solaris 11.4 の /usr/bin/grep には -E が無い。tree-patch-rust-bin.sh が
# grep -qE で当て物の有無を見ていて、illegal option で落ちた exit 1 を
# 「当たらなかった」と読み、「Darwin の深い -id が残っている」という測って
# いない主張を出して job を落とした。上の第一段は -E を勧めるので、第一段
# だけでは**この型は増える**。
#
# 対象を名前で書き並べない。SunOS の job が在る workflow から TREE_PATCH と
# TREE_PKGS/PKGS を引いて、その当て物と verify を対象にする。package が
# Solaris の matrix に増えたとき、黙って対象から外れないため。
echo
echo "SunOS の箱で走る script の -E を見る"
G2=$G
sun_scripts() {
	find "$ROOT/.github/workflows" -name '*.yml' -print 2>/dev/null |
	while read -r y; do
		# SunOS 系の job を持つ workflow だけ
		$G2 -qi -e 'solaris-vm' -e 'openindiana-vm' "$y" 2>/dev/null || continue
		# TREE_PATCH に挙がっている applier
		$G2 -h 'tree-patch-[a-z0-9-]*\.sh' "$y" 2>/dev/null |
		tr ' ' '\n' | $G2 -o 'tree-patch-[a-z0-9-]*\.sh' 2>/dev/null ||
		$G2 -h -o 'tree-patch-[a-z0-9-]*\.sh' "$y" 2>/dev/null
		# TREE_PKGS / PKGS から verify-<pkg>.sh を組み立てる
		$G2 -h -E '^[[:space:]]*(TREE_)?PKGS:' "$y" 2>/dev/null |
		sed 's/^[^:]*://' | tr -d "'\"" | tr ' ' '\n' |
		while read -r _p; do
			# PKGS: '' のときに verify-.sh という無い名前が
			# 出る。空は捨てる。
			case $_p in "") continue ;; esac
			case $_p in */*) ;; *) continue ;; esac
			echo "verify-${_p##*/}.sh"
		done
		# 木を当てる側の driver 自身も箱の中で走る
		echo build-on-bsd.sh
	done | sort -u
}
# 呼び出しだけを数える。comment と echo の文面は除く。最初これを入れずに
# 走らせて、build-on-bsd.sh の「-E 無い」という**説明文**を違反として
# 挙げた。検査の側も自分が何を見ているか言えないといけない。
#
# probe の二行も除く。あれは -E が在るかを測るための呼び出しで、落ちたら
# 「無い」が正しい答なので誤読が起きない唯一の場所。
sun_hits() {
	$G2 -n -e 'grep -[a-zA-Z]*[EP]' -e 'egrep' "$1" 2>/dev/null |
	$G2 -v -E '^[0-9]+:[[:space:]]*#' |
	$G2 -v -E "^[0-9]+:[[:space:]]*echo " |
	$G2 -v "printf 'ab" || true
}
bad2=""
for _f in $(sun_scripts); do
	[ -f "$D/$_f" ] || continue
	_hits=$(sun_hits "$D/$_f")
	[ -n "$_hits" ] && bad2="$bad2
$(printf '%s\n' "$_hits" | sed "s|^|$_f:|")"
done
bad2=$(printf '%s' "$bad2" | $G2 -c . || true)
[ -n "$bad2" ] || bad2=0
echo "  対象: $(sun_scripts | tr '\n' ' ')"
if [ "$bad2" -eq 0 ]; then
	echo "  SunOS で走る script の -E/-P/egrep: 0 件"
else
	echo "!! SunOS で走る script が -E/-P/egrep を $bad2 件使っている" >&2
	for _f in $(sun_scripts); do
		[ -f "$D/$_f" ] || continue
		sun_hits "$D/$_f" | sed "s|^|   $_f:|" >&2
	done
	echo "   Solaris の /usr/bin/grep には -E が無い。pattern を素の BRE で" >&2
	echo "   書くこと (bracket と * で足りることが多い)。" >&2
	exit 1
fi
[ "$n" -eq 0 ] || exit 1
