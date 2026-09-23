#!/bin/sh
#
# elisp package を素の名前で要求している行を探す。
#
#	sh check-elisp-prefix.sh [<pkgsrc の根>]
#
# pkgsrc の emacs framework は、package 名の前に ${EMACS_PKGNAME_PREFIX} を
# 付ける。いま中身は flavour だけ (GNU Emacs は空、XEmacs は "xemacs-") だが、
# 版まで入れる話が進んでいる。そうすると
#
#	emacs30-apel   xemacs214-apel   xemacs215-apel
#
# のように分かれる。名乗る側 (buildlink3.mk) は全部この変数を使っているので
# 一緒に動くが、**頼む側が素の名前を直書きしていると、そこだけ取り残される。**
#
# いまは prefix が空なので両方が同じ名前に落ちて通ってしまい、壊れているのが
# 見えない。prefix を入れた瞬間に、満たされない依存として出る。
#
#	ERROR: apel>=10.8 emacs30nox-apel>=10 is not installed
#
# 2026-09-17 に木ぜんぶを数えて三つ在った。下の一覧はその三つで、上流が直す
# までの既知分。**四つ目が増えたらここで落とす。**
KNOWN='devel/flim misc/emacs-wiki devel/doxymacs'

T=${1:-/usr/pkgsrc}
[ -d "$T/mk" ] || { echo "$T は pkgsrc の根ではない"; exit 1; }

# 展開の途中の木を測ると、静かに少ない数を返して通る。実際 55 カテゴリまで
# 展開された木で「17 個」が「8 個」になり、見つけるべき三つのうち二つが
# 落ちたまま rc=0 になった。根が在ることだけでは足りない。
n=$(find "$T" -name Makefile -maxdepth 3 2>/dev/null | wc -l | tr -d ' ')
if [ "$n" -lt 10000 ]; then
	echo "★ Makefile が $n 本しかない。木が揃っていない"
	exit 1
fi

# 木は読むだけ。数えた結果は外に置く。
HITS=${TMPDIR:-/tmp}/elisp-prefix-new.$$
trap 'rm -f "$HITS"' 0 1 2 15
: > "$HITS"

# 名乗る側: buildlink3.mk が ${EMACS_PKGNAME_PREFIX} を付けている package
names=$(grep -rh 'BUILDLINK_API_DEPENDS.*${EMACS_PKGNAME_PREFIX}' \
	  "$T" --include=buildlink3.mk 2>/dev/null \
	| sed -e 's/.*BUILDLINK_API_DEPENDS\.//' -e 's/[^A-Za-z0-9_.+-].*//' \
	      -e 's/+$//' \
	| sort -u)
[ -n "$names" ] || { echo "★ 名乗る側が一つも見つからない。検査が働いていない"; exit 1; }

echo "--- prefix 付きで名乗る elisp package: $(echo "$names" | wc -l | tr -d ' ') 個 ---"

# 木を名前の数だけ走査すると、遅いゲストで何分もかかる。一回で済ませる。
alt=$(echo "$names" | tr '\n' '|' | sed 's/|$//')

# 頼む側: DEPENDS か BUILDLINK_API_DEPENDS に素の名前を書いている行。
# ${EMACS_PKGNAME_PREFIX} を使っている行は正しいので外す。
grep -rn -E "^[^#]*((BUILDLINK_API_DEPENDS\.($alt)[ 	]*\+?=)|(DEPENDS[ 	]*\+?=[ 	]*($alt)[<>=-]))" \
  "$T" --include=Makefile --include='*.mk' 2>/dev/null \
| grep -v 'EMACS_PKGNAME_PREFIX' \
| while IFS= read -r line; do
	f=${line%%:*}
	d=$(echo "${f#$T/}" | sed 's|/[^/]*$||')
	case " $KNOWN " in
	*" $d "*) printf '    既知  %s\n' "${line#$T/}"
	          echo "known $d" >> "$HITS" ;;
	*)        printf '    ★新  %s\n' "${line#$T/}"
	          echo "new $d" >> "$HITS" ;;
	esac
done

new=$(grep -c '^new ' "$HITS" 2>/dev/null); new=${new:-0}
known=$(grep -c '^known ' "$HITS" 2>/dev/null); known=${known:-0}

if [ "$new" -gt 0 ]; then
	echo "=== 素の名前で elisp package を要求している新しい行が $new 本 ==="
	echo '    ${EMACS_PKGNAME_PREFIX} を付けるか、既知なら KNOWN へ足す'
	exit 1
fi
echo "--- 素の名前での要求 $known 本、どれも既知 ---"
