#!/bin/sh
#
# その package を建てるとき、実際に何が呼ばれるかを挙げる。
#
#	sh show-build-entry.sh <pkgsrc の根> <package> [<package> ...]
#
# 手元で el を直接 batch-byte-compile して「通った」と言っても、package が
# 通るとは限らない。上流が駆動 file を挟んでいることがあり、そこに build を
# 止める仕掛けが入っている。
#
# 2026-09-23 に iiimecf がこれで落ちた。lisp は当て物で Mule-UCS 無しに
# 動くようにしてあったが、iiimcf-comp.el が
#
#	(while (null (locate-library "un-define"))
#	  ... (setq path (read-from-minibuffer "")))
#
# と minibuffer で訊く。batch では stdin が EOF なので
# "End of file during parsing" で止まる。
#
# 落とす検査ではない。**測る前に同じ呼び方を知るための一覧**。
set -u

T=${1:-/usr/pkgsrc}
shift 2>/dev/null || true

for p in "$@"; do
	mk=$T/$p/Makefile
	[ -f "$mk" ] || { echo "--- $p  Makefile が無い"; continue; }
	echo "--- $p"
	# grep の BRE では [ \t] の \t が literal の t になる。実 tab を書く。
	if grep -qE '^NO_BUILD[	 ]*=[	 ]*yes' "$mk"; then
		echo "      NO_BUILD。建てない"
		continue
	fi
	grep -nE '^(do-build|BUILD_TARGET|MAKE_ENV|USE_TOOLS)' "$mk" | sed 's/^/      /'
	# do-build の中身を一段出す
	sed -n '/^do-build:/,/^$/p' "$mk" | sed -n '2,6p' | sed 's/^/      | /'
	# pkgsrc 側に何も書いていなければ上流の Makefile 任せ。展開済みの木が
	# 在れば、そこが何を読むかまで出す。
	w=$(ls -d "$T/$p"/work/*/ 2>/dev/null | head -1)
	if [ -n "$w" ]; then
		for f in "$w"Makefile "$w"Makefile.in; do
			[ -f "$f" ] || continue
			# grep は \t を literal の t と読む。実 tab を書く。
			grep -nE '^[A-Z]*(DEPS|BATCHFLAGS|EMACS)[	 ]*=' "$f" \
			  | sed "s|^|      ${f##*/}: |"
			sed -n '/^\.el\.elc:/,+1p' "$f" | sed 's/^/      | /'
		done
	fi
	echo "      ↑ この呼び方と同じ形で手元を測る"
done
