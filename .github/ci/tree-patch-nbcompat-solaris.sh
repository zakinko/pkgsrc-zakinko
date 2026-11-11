#!/bin/sh
# pkgtools/libnbcompat の lchflags.c は、chflags の無い OS を __illumos__ と
# __linux__ で見分けている。Oracle Solaris 11.4 はどちらも定義しないので
# chflags() を宣言なしで呼び、gcc 14 では implicit declaration が error に
# なって bootstrap がそこで止まる (run 43078238828、Solaris 11.4-gcc)。
# illumos と Solaris の両方が定義する __sun を足して ENOSYS の側へ寄せる。
#
#   sh tree-patch-nbcompat-solaris.sh <pkgsrc のツリー>
set -e
F=$1/pkgtools/libnbcompat/files/lchflags.c
grep -q '^#if defined(__illumos__) || defined(__linux__)$' "$F" || {
	echo "!! $F の形が想定と違う。当てない" >&2; exit 1; }
sed 's/^#if defined(__illumos__) || defined(__linux__)$/#if defined(__illumos__) || defined(__linux__) || defined(__sun)/' \
	"$F" > "$F.new"
mv "$F.new" "$F"
grep -n '__sun' "$F"
