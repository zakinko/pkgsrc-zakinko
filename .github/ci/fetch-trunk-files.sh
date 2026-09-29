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
OUT=$SRC/trunk
rm -rf "$OUT"; mkdir -p "$OUT"
API=https://api.github.com/repos/NetBSD/pkgsrc
# 無名だと 60 回/時。walk が directory ごとに叩くので token を渡せるなら渡す。
api() {
	if [ -n "${GH_TOKEN:-}" ]; then
		curl -sS -H "Authorization: Bearer $GH_TOKEN" "$@"
	else
		curl -sS "$@"
	fi
}

# 取る物は全部同じ commit から。trunk の名前で取ると、取っている間に
# 動いた file が混ざる。
api "$API/commits?sha=trunk&per_page=1" \
	| awk -F'"' '/"sha"/ && !s {s=$4} /"date"/ && !d {d=$4} END {print s, d}' > "$OUT/COMMIT"
SHA=$(awk '{print $1}' "$OUT/COMMIT")
[ -n "$SHA" ] || { echo "trunk の commit が引けない"; exit 1; }
RAW=https://raw.githubusercontent.com/NetBSD/pkgsrc/$SHA

# 触る file: pkg-fixes/*/ の差分の --- 行と、上の階の *.orig が指す二つ。
# not-sent/ は当てないので取らない。
{
	# +++ の側を読む。--- 側は diff を取った箱の絶対 path のことがあり
	# (/usr/pkgsrc/mail/vm/Makefile)、そのまま URL にすると 404 になる。
	# 2026-09-26 に上流が大半を取り込み、framework/ と adaptations/ は空に
	# なった。空の glob は grep が文句を言うだけなので黙らせる。
	grep -h '^+++ ' "$SRC"/pkg-fixes/framework/*.diff "$SRC"/pkg-fixes/fixes/*.diff \
		"$SRC"/pkg-fixes/adaptations/*.diff 2>/dev/null | awk '{print $2}'
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

# 建てる package の directory は丸ごと取る。差分が触る file だけを被せる
# と、その package の残りは ゲストの木 (cdn の tarball か image) のまま
# になり、trunk で直った物を古い形で建てる。run 36261175795 は
# www/emacs-w3m で落ちたが、tarball の Makefile が rev 1.42
# (2026-09-26、WRKSRC の直し) より前だったためで、枠組みとは関係が無い。
# 並びは verify-emacs-framework.sh の PKGS と、同居版が土台にする
# editors/emacs30*。verify 側は DIRS に無い package を建てるとき ★ を出す。
# 丸ごと置き換えるので、trunk で消えた patch が残ることもない。
DIRS="devel/apel devel/flim devel/zig-mode textproc/dictem editors/gnuserv www/emacs-w3m
	net/twittering-mode textproc/emacs-dict-client devel/cqual inputmethod/tamago-tsunagi
	editors/emacs30 editors/emacs30-nox11"
: > "$OUT/DIRS.files"
walk() {
	# contents API は一階ずつ。patches/ と files/ は下りる。
	api "$API/contents/$1?ref=$SHA" | python3 -c '
import json,sys
for e in json.load(sys.stdin):
    print(e["type"], e["path"])'
}
for d in $DIRS; do
	echo "$d" >> "$OUT/DIRS"
	walk "$d" | while read -r t p; do
		case $t in
		file) echo "$p";;
		dir)  walk "$p" | awk '$1=="file"{print $2} $1=="dir"{print "★DIR " $2}';;
		esac
	done >> "$OUT/DIRS.files"
done
if grep -q '^★DIR' "$OUT/DIRS.files"; then
	echo "  ★ 三階目の directory が在る (取らない):"; grep '^★DIR' "$OUT/DIRS.files"
	miss=$((miss+1))
fi
dn=0
while read -r f; do
	mkdir -p "$OUT/tree/$(dirname "$f")"
	code=$(curl -sS -o "$OUT/tree/$f" -w '%{http_code}' "$RAW/$f")
	if [ "$code" = 200 ]; then dn=$((dn+1)); else
		echo "  ★ $code $f"; miss=$((miss+1))
	fi
done <<EOT
$(grep -v '^★DIR' "$OUT/DIRS.files")
EOT
for d in $DIRS; do
	[ -f "$OUT/tree/$d/Makefile" ] || { echo "  ★ $d の Makefile が無い"; miss=$((miss+1)); }
done

echo "trunk $(cat "$OUT/COMMIT")"
echo "取れた $n / 取れない $miss (FILES $(wc -l < "$OUT/FILES" | tr -d ' '))"
echo "丸ごと取った directory $(wc -l < "$OUT/DIRS" | tr -d ' ') 本、file $dn 本"
[ "$miss" = 0 ]
