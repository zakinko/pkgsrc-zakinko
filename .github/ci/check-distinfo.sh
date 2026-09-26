#!/bin/sh
# 当て物と distinfo の SHA1 が合っているかを見る。
#
#   sh .github/ci/check-distinfo.sh [パッケージ ...]
#
# なぜ要るか
# ----------
# xwpe/distinfo が当て物 3 本を古い値のまま持っていた。pkgsrc は checksum
# の合わない当て物を黙って読み飛ばし、そのあと「壊れた当て物がある」と
# 言って止まる。落ちるのは VM の中の patch 段で、そこへ辿り着くまでに
# bootstrap と依存を組む時間が要る。2026-08-24 の run はこれで NetBSD の
# 三つと FreeBSD と OpenBSD を落とし、合わせて 8 時間を使った。
#
# 同じことは awk と shasum で数秒で分かる。ここで止める。
#
# pkgsrc 側の算法は mk/checksum が持っていて、当て物の checksum は
# $NetBSD$ の行を落としてから取る。CVS が展開する行なので、そこを数えると
# tree に入った瞬間に値が変わってしまうため。
PKGSRCDIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$PKGSRCDIR" || exit 1

# 回すのは runner の上だが、手元で確かめたくなるのは NetBSD の箱である。
# 名前が三通りある。
if command -v shasum > /dev/null 2>&1; then
	SHA1='shasum'
elif command -v sha1sum > /dev/null 2>&1; then
	SHA1='sha1sum'
elif command -v cksum > /dev/null 2>&1; then
	SHA1='cksum -a sha1'
else
	echo "FAIL: sha1 を取る道具が無い"; exit 1
fi

if [ $# -gt 0 ]; then
	dirs=$*
else
	dirs=$(for d in */; do [ -d "$d/patches" ] && echo "${d%/}"; done)
fi

rc=0
n=0
for d in $dirs; do
	[ -d "$d/patches" ] || continue
	if [ ! -f "$d/distinfo" ]; then
		echo "FAIL: $d/patches は在るのに $d/distinfo が無い"
		rc=1
		continue
	fi

	for p in "$d"/patches/patch-*; do
		[ -f "$p" ] || continue
		b=${p##*/}
		n=$((n + 1))

		# EUC-JP の当て物が anthy に在る。ここを既定の locale で読むと
		# sed が illegal byte sequence で落ち、合っているものを不一致と
		# 報告する。C で読む。
		got=$(LC_ALL=C sed -e '/\$NetBSD.*\$/d' "$p" |
			$SHA1 | awk '{print $1}')
		want=$(awk -v b="$b" '$1 == "SHA1" && $2 == "("b")" { print $4 }' \
			"$d/distinfo")

		if [ -z "$want" ]; then
			echo "FAIL: $d/distinfo に $b の行が無い"
			rc=1
		elif [ "$want" != "$got" ]; then
			echo "FAIL: $d/$b"
			echo "      distinfo: $want"
			echo "      当て物:   $got"
			rc=1
		fi
	done

	# 消した当て物の行が distinfo に残っていると、pkgsrc は在らない
	# ファイルを当てにいって止まる。
	#
	# SHA1 は配布物の側にも使われている (emacs22 などが持っている) ので、
	# patch- で始まる名前だけを見る。パイプで回すと while が子 shell に
	# なって rc が戻らないため、一度変数へ入れる。
	stale=$(awk '$1 == "SHA1" && $2 ~ /^\(patch-/ {
			gsub(/[()]/, "", $2); print $2
		}' "$d/distinfo")
	for b in $stale; do
		[ -f "$d/patches/$b" ] && continue
		echo "FAIL: $d/distinfo が $b を挙げているが patches に無い"
		rc=1
	done
done

if [ $rc -eq 0 ]; then
	echo "=== 当て物 $n 本、distinfo と合っている ==="
else
	echo "=== distinfo が合っていない。make mps を回すこと ==="
fi
exit $rc
