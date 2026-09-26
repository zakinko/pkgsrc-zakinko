#!/bin/sh
#
# openjdk* が指している「上流の tag」と「BSD 移植の diff」が、いまも噛み合って
# いるかを見る。
#
# これらの package は本体を openjdk から取り、BSD 移植を PATCHFILES で一枚
# 当てる形をしている。噛み合わなくなる道が二つあって、どちらも静かに壊れる。
#
#   1. 移植の tag が上流 tag の子孫でなくなる
#      GitHub の compare が返す A...B.diff は merge-base からの三点差なので、
#      子孫でなければ「新しい上流の変更を取り消す」hunk が混ざる。当たって
#      しまうので patch は成功し、建った JDK だけが古くなる。
#
#   2. 上流の tag を動かしたが、移植の diff がその木に当たらない
#      patch 段で止まるが、そこへ辿り着くのに VM と依存の build が要る。
#
# どちらも、VM を起こす前にここで分かる。
#
set -e

fail=0
found=0

for mk in */Makefile; do
	d=`dirname "$mk"`
	case "$d" in openjdk*) ;; *) continue ;; esac

	base=`sed -n 's/^BSD_PORT_BASE=[[:space:]]*//p' "$mk"`
	tag=`sed -n 's/^BSD_PORT_TAG=[[:space:]]*//p' "$mk"`
	gh=`sed -n 's/^GITHUB_TAG=[[:space:]]*//p' "$mk"`
	proj=`sed -n 's/^GITHUB_PROJECT=[[:space:]]*//p' "$mk"`
	site=`sed -n 's|^SITES\.[^=]*=[[:space:]]*||p' "$mk" | head -1`

	# 組み替えていない package はここでは見ない
	[ -n "$base" ] && [ -n "$tag" ] || continue
	found=`expr $found + 1`

	fork=`echo "$site" | sed -e 's|https://github.com/||' -e 's|/compare/.*||'`
	echo "=== $d"
	echo "    上流 $proj $gh"
	echo "    移植 $fork $base ... $tag"

	# (1) 子孫かどうか。behind が立てば、当てると上流が巻き戻る。
	json=`curl -fsSL "https://api.github.com/repos/$fork/compare/$base...$tag"`
	behind=`echo "$json" | sed -n 's/.*"behind_by": *\([0-9]*\).*/\1/p' | head -1`
	if [ "x$behind" != "x0" ]; then
		echo "    NG: $tag は $base より $behind commit 遅れている。" >&2
		echo "        この差を当てると、その分の上流の変更が取り消される。" >&2
		fail=`expr $fail + 1`
		continue
	fi
	echo "    子孫である (behind 0)"

	# (2) 実際に当たるか。上流の tarball を取って空当てする。
	enc=`echo "$gh" | sed 's/+/%2B/g'`
	work=`mktemp -d`
	curl -fsSL -o "$work/src.tar.gz" \
	    "https://github.com/openjdk/$proj/archive/refs/tags/$enc.tar.gz"
	curl -fsSL -o "$work/port.diff" \
	    "https://github.com/$fork/compare/$base...$tag.diff"
	mkdir "$work/x"
	tar xzf "$work/src.tar.gz" -C "$work/x"
	src=`echo "$work"/x/*`
	# -f と </dev/null: 当たらない file が在ると patch は名前を訊きに来る。
	# 答える口が無いので、そのまま張り付いて終わらなくなる。
	if (cd "$src" && patch -p1 --dry-run -f --batch \
	    < "$work/port.diff" > "$work/dry.log" 2>&1); then
		n=`grep -c '^patching file' "$work/dry.log" || true`
		echo "    当たる ($n file)"
	else
		echo "    NG: 移植の diff が $gh に当たらない" >&2
		grep -E 'FAILED|can.t find file' "$work/dry.log" | head -5 >&2
		fail=`expr $fail + 1`
	fi
	rm -rf "$work"
done

# 何も見ずに通る検査は、通ったことにならない。
if [ "$found" -eq 0 ]; then
	echo "NG: BSD_PORT_BASE を持つ package が一つも無い。検査が空回りしている。" >&2
	exit 1
fi

echo
echo "$found 個を見て、駄目だったのは $fail 個"
[ "$fail" -eq 0 ]
