#!/bin/sh
# 送る差分が触る file を、pkgsrc の trunk (GitHub の mirror) から今日の
# 現物で取ってきて $SRC/trunk/ に敷く。verify-emacs-framework.sh が当てる
# 前に木へ被せる。
#
# なぜ要るか。ゲストの image は /usr/pkgsrc を焼き込んでいて (2026-08-25、
# modules.mk 1.40)、cdn の tarball も trunk より遅れる。run 35317577955 は
# その木に当てて pcl-cvs.diff と tamago.diff が空当てで落ちたが、trunk の
# 現物には当たる。古い木で「当たらない」と出ても、送る相手は trunk なので
# 何も測っていない。逆に古い木で当たっても、trunk で当たる保証は無い。
#
# 触る file だけを被せる。木を丸ごと置き換えると、その差にある上流の変更
# を黙って戻す (verify-emacs-framework.sh の注記)。被せた file の一覧と、
# trunk の commit を $SRC/trunk/COMMIT に残し、log に出す。
#
# ホスト側で走る。ゲストの NetBSD は焼きたてだと https が通らない。
set -eu
SRC=${1:?usage: fetch-trunk-files.sh <dir holding pkg-fixes/ and *.orig>}
RAW=https://raw.githubusercontent.com/NetBSD/pkgsrc/trunk
OUT=$SRC/trunk
rm -rf "$OUT"; mkdir -p "$OUT"

# 触る file: pkg-fixes/*/ の差分の --- 行と、上の階の *.orig が指す二つ。
# not-sent/ は当てないので取らない。
{
	grep -h '^--- ' "$SRC"/pkg-fixes/framework/*.diff "$SRC"/pkg-fixes/fixes/*.diff \
		"$SRC"/pkg-fixes/adaptations/*.diff | awk '{print $2}' | sed 's/\.orig$//'
	echo editors/emacs/modules.mk
} | sort -u > "$OUT/FILES"

n=0; miss=0
while read -r f; do
	mkdir -p "$OUT/$(dirname "$f")"
	code=$(curl -sS -o "$OUT/$f" -w '%{http_code}' "$RAW/$f")
	if [ "$code" = 200 ]; then n=$((n+1)); else
		# 差分が新しく作る file (--- /dev/null) は 404 で正しい。それ以外は
		# path が違うか trunk から消えたかで、当てても意味が無い。
		echo "  ★ $code $f"; rm -f "$OUT/$f"; miss=$((miss+1))
	fi
done < "$OUT/FILES"

# 何に当てたのかを名指しできるように。
curl -sS 'https://api.github.com/repos/NetBSD/pkgsrc/commits?sha=trunk&per_page=1' \
	| awk -F'"' '/"sha"/ && !s {s=$4} /"date"/ && !d {d=$4} END {print s, d}' > "$OUT/COMMIT"
echo "trunk $(cat "$OUT/COMMIT")"
echo "取れた $n / 取れない $miss (FILES $(wc -l < "$OUT/FILES" | tr -d ' '))"
[ "$miss" = 0 ]
