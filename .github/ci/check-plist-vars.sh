#!/bin/sh
#
# PLIST の中の ${...} が、その package で本当に定義されるかを見る。
#
#	sh check-plist-vars.sh <pkgsrc の根> <package> [<package> ...]
#
# 定義されない変数は展開されず、literal のまま PLIST に載る。すると
#
#	pkg_create: can't stat .../${FOR_emacs21}share/emacs/site-lisp/...
#
# で install の段まで行ってから落ちる。**build は通ってしまう**ので、
# 気付くのが遅い。2026-09-23 に emacs-ilisp がこれで落ちた。古い PLIST から
# ${FOR_emacs21} を引き写していたが、emacs21 は木から消えていて
# editors/emacs/modules.mk の FOR_* の一覧に無い。
#
# 見るのは字面だけ。make show-var は PLIST の中までは展開しない。
set -u

T=${1:-/usr/pkgsrc}
shift 2>/dev/null || true
[ -d "$T/mk" ] || { echo "$T は pkgsrc の根ではない"; exit 1; }

# modules.mk が定義する FOR_/NOTFOR_ の版名を拾う
MM=$T/editors/emacs/modules.mk
if [ -f "$MM" ]; then
	# 二つの sed 式を並べると前者が後者を食う。範囲指定だけにする。
	VERS=$(sed -n '/_EMACS_VERSIONS_ALL/,/^$/p' "$MM" \
	       | tr ' \t\\' '\n\n\n' | grep -E '^x?emacs[0-9]' | sort -u | tr '\n' ' ')
else
	VERS=
fi

ng=0
for p in "$@"; do
	pl=$T/$p/PLIST
	[ -f "$pl" ] || { echo "  --- $p  PLIST が無い"; continue; }
	vars=$(grep -oE '\$\{[A-Za-z0-9_.]+\}' "$pl" | sort -u | tr -d '${}')
	for v in $vars; do
		case $v in
		EMACS_LISPPREFIX|EMACS_INFOPREFIX|EMACS_ETCPREFIX|PKGMANDIR|PREFIX)
			continue ;;
		PLIST.*)
			n=${v#PLIST.}
			if grep -q "PLIST_VARS+=.*\\b$n\\b" "$T/$p/Makefile" 2>/dev/null; then
				continue
			fi
			echo "  --- $p  ★ PLIST_VARS に $n が無い"; ng=$((ng+1)) ;;
		FOR_*|NOTFOR_*)
			n=${v#FOR_}; n=${n#NOTFOR_}
			case $n in emacs|xemacs|emacs_x|emacs_nox|emacs_no_byte_compile) continue ;; esac
			case " $VERS " in
			*" $n "*) : ;;
			*) echo "  --- $p  ★ $v は定義されない ($n は木に無い)"; ng=$((ng+1)) ;;
			esac ;;
		esac
	done
done
[ "$ng" = 0 ] && echo "--- PLIST の変数は全部定義されている ---"
exit $ng
