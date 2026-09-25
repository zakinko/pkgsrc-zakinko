#!/bin/sh
# Debian の rootfs を foreign arch で作り、docker image として取り込む。
#
# なぜ要るか。go-bin は ONLY_FOR_PLATFORM に linux-mips / linux-mipsle /
# linux-ppc64 を並べるのに、公式の docker image がどこにも無い。
#
#	debian の公式 arch 名前空間        mips mipsel mips64 は無い
#	debian/eol:bullseye               386 amd64 arm arm64 mips64le ppc64le s390x
#	Debian ports (unstable)           alpha hppa hurd m68k powerpc ppc64 sh4 sparc64 x32
#	archive.debian.org bullseye       mipsel と mips64el は在る、mips は無い
#	archive.debian.org stretch        mipsel mips mips64el が在る
#
# 並べるだけで一度も動かさないのは「動きます」と言って測っていないことなので、
# rootfs を自分で作る。
#
#	sh make-debian-rootfs.sh <arch> <suite> <mirror> <image 名>
#
# mips (BE) は stretch にしか無く、そちらは 2017 年で gcc 6。pkgsrc-current が
# それで bootstrap するかは分からない。分からないことを測るのが目的。
set -e
ARCH=${1:?usage: $0 <arch> <suite> <mirror> <tag>}
SUITE=${2:?}
MIRROR=${3:?}
TAG=${4:?}

sudo apt-get update -qq
sudo apt-get install -y -qq debootstrap qemu-user-static binfmt-support \
	debian-ports-archive-keyring > /dev/null

W=$(mktemp -d)
R="$W/rootfs"

# Debian ports は鍵が別。archive.debian.org は期限切れの鍵を持つので
# --no-check-gpg にする。取るのは公開されている rootfs で、そこから
# 秘密を読むわけではない。
# Ubuntu の debian-ports-archive-keyring は、いま debian-ports に署名して
# いる鍵より古い。そのまま使うと
#   E: Release signed by unknown key (key id C6894E6BB25B9C99)
#   The specified keyring ... may be incorrect or out of date.
# で止まる。現行のものを Debian の main archive から取る。
KEY=
case $MIRROR in
*debian-ports*)
	# 取り出す手は fetch-debian-ports-keyring.sh に在る。出来合いの
	# loongarch64 の image の中の apt にも同じ鍵が要るので、二箇所から
	# 呼べるように分けてある。
	KD=$(mktemp -d)
	K="$KD/debian-ports-archive-keyring.gpg"
	sh "$(dirname "$0")/fetch-debian-ports-keyring.sh" "$K"
	KEY="--keyring=$K"
	;;
*archive.debian.org*) KEY="--no-check-gpg" ;;
esac

echo "=== debootstrap 一段目 ($ARCH $SUITE)"
sudo debootstrap --foreign --arch="$ARCH" --variant=minbase $KEY \
	"$SUITE" "$R" "$MIRROR"

echo "=== qemu を入れて二段目"
sudo cp "/usr/bin/qemu-$(
	case $ARCH in
	mipsel) echo mipsel ;;
	mips)   echo mips ;;
	mips64el) echo mips64el ;;
	ppc64)  echo ppc64 ;;
	*)      echo "$ARCH" ;;
	esac)-static" "$R/usr/bin/"
sudo chroot "$R" /debootstrap/debootstrap --second-stage

echo "=== arch を確かめる"
got=$(sudo chroot "$R" /bin/uname -m 2>/dev/null || echo "?")
echo "  chroot の uname -m: $got"
case "$got" in
x86_64|"?") echo "!! 翻訳が効いていない。ここで止める"; exit 1 ;;
esac

echo "=== docker image に取り込む"
sudo tar -C "$R" -c . | docker import - "$TAG"
docker images "$TAG" --format '  {{.Repository}}:{{.Tag}}  {{.Size}}'
sudo rm -rf "$W"
