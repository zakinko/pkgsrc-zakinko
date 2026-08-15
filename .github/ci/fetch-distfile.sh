#!/bin/sh
# 配布物を取ってきて、distinfo と突き合わせる。GitHub Actions の Linux
# runner で走る。
#
# ftp.m17n.org は消滅していて、残っているのは KAIST の書庫だけ。取れた
# ものは actions/cache に残すので、書庫が落ちていても回る。
#
# 期待するチェックサムは distinfo から読む。ここに書き写すと、いつか
# 片方だけが古くなる。

set -e

TREE=$(cd "$(dirname "$0")/../.." && pwd)
cd "$TREE"

DIST=distfiles/mule-2.3.tar.gz

mkdir -p distfiles
if [ ! -s "$DIST" ]; then
	curl -fsSL -o "$DIST" \
		http://ftp.kaist.ac.kr/hangul/mirror/mule/mule-2.3.tar.gz
fi

SUM=$(awk '$1 == "SHA512" && $2 == "(mule-2.3.tar.gz)" { print $4 }' \
	mule/distinfo)
[ -n "$SUM" ] || { echo "distinfo に mule-2.3.tar.gz の SHA512 が無い"; exit 1; }

# Linux の runner は sha512sum、macOS の runner は shasum しか持っていない。
if command -v sha512sum > /dev/null 2>&1; then
	echo "$SUM  $DIST" | sha512sum -c -
else
	echo "$SUM  $DIST" | shasum -a 512 -c -
fi
