#!/bin/sh
# debian-ports の現行の署名鍵を取り出して、引数の場所に置く。
#
#   sh fetch-debian-ports-keyring.sh <出力する .gpg の path>
#
# Ubuntu (runner) の debian-ports-archive-keyring は、いま debian-ports に
# 署名している鍵より古い。そのまま使うと
#   E: Release signed by unknown key (key id C6894E6BB25B9C99)
# で止まる。版を決め打ちにもしない (鍵は回るので、決め打ちは次の回転で
# 同じ症状に戻る)。pool の一覧から今在る版を読む。
#
# make-debian-rootfs.sh が debootstrap の --keyring に渡すのと、
# loongarch64 のように出来合いの image の中の apt に渡すのと、二箇所で
# 同じものが要る。二つに写すと片方だけ直る形になるので一本にした。
set -e
OUT=${1:?usage: $0 <out.gpg>}
B=http://deb.debian.org/debian/pool/main/d/debian-ports-archive-keyring
KD=$(mktemp -d)
trap 'rm -rf "$KD"' 0
deb=$(curl -sf "$B/" |
	sed -n 's/.*\(debian-ports-archive-keyring_[0-9.]*_all\.deb\).*/\1/p' |
	sort -u | tail -1)
[ -n "$deb" ] || { echo "!! 現行の keyring が見つからない ($B)" >&2; exit 1; }
echo "  keyring: $deb"
curl -sfo "$KD/k.deb" "$B/$deb"
( cd "$KD" && ar x k.deb && tar xf data.tar.* )
K="$KD/usr/share/keyrings/debian-ports-archive-keyring.gpg"
[ -f "$K" ] || {
	echo "!! keyring の中身が取り出せない" >&2
	ls -R "$KD" | head -20 >&2
	exit 1
}
mkdir -p "$(dirname "$OUT")"
cp "$K" "$OUT"
# 中身が鍵であることを確かめる。名前が在るだけでは足りない。
if command -v gpg > /dev/null 2>&1; then
	gpg --show-keys --with-colons "$OUT" 2>/dev/null | grep -q '^pub' || {
		echo "!! 取り出した file が鍵として読めない" >&2; exit 1; }
	echo "  鍵の数: $(gpg --show-keys --with-colons "$OUT" 2>/dev/null | grep -c '^pub')"
fi
echo "  置いた: $OUT ($(wc -c < "$OUT" | tr -d ' ') bytes)"
