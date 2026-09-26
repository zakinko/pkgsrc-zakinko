#!/bin/sh
# 配布物を取ってきて、distinfo と突き合わせる。GitHub Actions の Linux
# runner で走る。
#
#	sh fetch-distfile.sh [パッケージ]	既定は mule2
#
# 名前もチェックサムも distinfo から読む。ここに書き写すと、いつか片方
# だけが古くなる。実際そうなった: 8d71ae8 で mule が Mule 1.1 になった後も
# mule/distinfo から mule-2.3.tar.gz を読もうとして、illumos と他 BSD が
# build に入る前に全滅していた。
#
# 取得元だけは package ごとに違う。ここが要るのは mule2 (Mule 2.3) だけで、
# ftp.m17n.org が消滅していて KAIST の書庫しか残っていないため、落ちていても
# 回せるよう手元に取って actions/cache に載せる。GitHub から取るもの
# (mule = Mule 1.1) は VM の中で pkgsrc に取らせれば足りるので、ここでは
# 何もしないで抜ける。

set -e

PKG=${1:-mule2}
TREE=$(cd "$(dirname "$0")/../.." && pwd)
cd "$TREE"

[ -f "$PKG/distinfo" ] || {
	echo "$PKG/distinfo が無い。何もしない。"
	exit 0
}

# distinfo の先頭の配布物を見る。当て物の行 (patch-*) は名前で外れる。
NAME=$(awk '$1 == "SHA512" { n = $2; gsub(/[()]/, "", n); if (n !~ /^patch-/) { print n; exit } }' "$PKG/distinfo")
SUM=$(awk -v n="$NAME" '$1 == "SHA512" && $2 == "(" n ")" { print $4; exit }' "$PKG/distinfo")

[ -n "$NAME" ] && [ -n "$SUM" ] || {
	echo "$PKG/distinfo から配布物を読めない。何もしない。"
	exit 0
}

case $NAME in
mule-2.3.tar.gz)
	URL=http://ftp.kaist.ac.kr/hangul/mirror/mule/$NAME
	;;
*)
	echo "$NAME はここでは取らない (pkgsrc に取らせる)。"
	exit 0
	;;
esac

DIST=distfiles/$NAME
mkdir -p distfiles
[ -s "$DIST" ] || curl -fsSL -o "$DIST" "$URL"

# Linux の runner は sha512sum、macOS の runner は shasum しか持っていない。
if command -v sha512sum > /dev/null 2>&1; then
	echo "$SUM  $DIST" | sha512sum -c -
else
	echo "$SUM  $DIST" | shasum -a 512 -c -
fi
