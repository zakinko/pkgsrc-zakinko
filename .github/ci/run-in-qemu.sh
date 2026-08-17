#!/bin/sh
# netbsd-ci-images のイメージを QEMU で起動し、その中で組んで検査を走らせる。
# GitHub Actions の Linux runner で動かす。
#
#   sh run-in-qemu.sh <arch>-<release> "<PKG_OPTIONS.mule>"
#   例: sh run-in-qemu.sh i386-11.0 "canna wnn4 x11"
#
# 上流 pkgsrc の package を見たいときは環境変数で渡す。zakinko カテゴリは
# 作らず、検査だけを送り込んで走らせる。
#
#   UPSTREAM_PKG=inputmethod/uim VERIFY_SCRIPT=verify-uim.sh \
#       sh run-in-qemu.sh amd64-10.1
#
# ここを使うのは、vmactions の netbsd-vm が GitHub の runner では KVM を
# 使えず TCG になるため。uim を回したら 4 時間で 8 パッケージしか組めず
# timeout に当たった。こちらのイメージはホストが x86_64 なので i386 でも
# amd64 でも KVM が効く。X のセットも入っているので X11_TYPE=native で
# 済み、modular X を積む必要もない。
#
# イメージは公式には配られていないので (配布物はインストーラが主で、
# インストール済みのものは amd64 の 10.0 以降しかない)、anita で組んだ
# ものを netbsd-ci-images の release から落とす。
#
# 起動と停止はあちらのスクリプトをそのまま使う。繋ぎ方はイメージに添えた
# .qemu に書いてあり、鍵は起動のたびにゲストがホストから取りに来る。同じ
# ことを二箇所に書くと必ず片方が古くなるので、持ってきて使う。

set -e

NAME=$1
OPTS=$2
[ -n "$NAME" ] || { echo "usage: $0 <arch>-<release> [pkg options]"; exit 1; }

IMGREPO=${IMGREPO:-zakinko/netbsd-ci-images}
IMGTAG=${IMGTAG:-images}
IMGREF=${IMGREF:-main}
PORT=${PORT:-2222}
WORK=${WORK:-$PWD/.vm}
TREE=$(cd "$(dirname "$0")/../.." && pwd)

mkdir -p "$WORK"
cd "$WORK"

echo "=== $NAME を用意する ==="
RAW=https://raw.githubusercontent.com/$IMGREPO/$IMGREF
for f in runvm.sh stopvm.sh; do
	[ -s "$f" ] || curl -fsSL -o "$f" "$RAW/$f"
done
REL=https://github.com/$IMGREPO/releases/download/$IMGTAG
for f in $NAME.qcow2 $NAME.qemu; do
	[ -s "$f" ] || { echo "--- $f を落とす ---"; curl -fsSL -o "$f" "$REL/$f"; }
done


# 落ちても VM を残さない。runner は使い捨てだが、手元で回したときに掴んだ
# ままだと次が起動できない。止め方は ACPI で、モニタの quit は使わない。
cleanup() {
	rc=$?
	DIR=. sh stopvm.sh "$NAME" > /dev/null 2>&1 || true
	exit $rc
}

echo "=== 起動 ==="
DIR=. sh runvm.sh "$NAME" "$PORT"
trap cleanup EXIT INT TERM

# 入り方は runvm.sh が決めて書き出す。古い sshd 向けの指定が要るので、
# ここで書き写さずに読む。
SSH=$(cat "$WORK/$NAME.ssh")

echo "=== pkgsrc を用意する ==="
$SSH sh -s <<'GUEST'
set -e
PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/pkg/bin:/usr/pkg/sbin
export PATH
if [ ! -d /usr/pkgsrc/mk ]; then
	ftp -o /tmp/pkgsrc.tar.gz http://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz
	tar xzf /tmp/pkgsrc.tar.gz -C /usr
	rm -f /tmp/pkgsrc.tar.gz
fi
mkdir -p /usr/pkgsrc/distfiles
GUEST

if [ -n "${UPSTREAM_PKG:-}" ]; then
	# 上流の package を見る。zakinko カテゴリは要らない。
	VERIFY_SCRIPT=${VERIFY_SCRIPT:-verify-pkg.sh}
	echo "=== 検査を送り込む ($UPSTREAM_PKG) ==="
	tar czf - -C "$TREE" .github/ci | $SSH "tar xzf - -C /tmp"

	echo "=== 検査を走らせる ==="
	$SSH "sh /tmp/.github/ci/$VERIFY_SCRIPT '$UPSTREAM_PKG'"
	exit $?
fi

$SSH sh -s <<'GUEST'
set -e
mkdir -p /usr/pkgsrc/zakinko
printf '# $NetBSD$\nCOMMENT=\tLocal\nSUBDIR+=\tmule\n.include "../mk/misc/category.mk"\n' \
	> /usr/pkgsrc/zakinko/Makefile
GUEST

echo "=== パッケージと検査を送り込む ==="
tar czf - -C "$TREE" mule .github/ci | $SSH "tar xzf - -C /tmp && \
	mkdir -p /usr/pkgsrc/zakinko/mule && \
	cp -R /tmp/mule/. /usr/pkgsrc/zakinko/mule/"
if [ -s "$TREE/distfiles/mule-2.3.tar.gz" ]; then
	$SSH "cat > /usr/pkgsrc/distfiles/mule-2.3.tar.gz" < "$TREE/distfiles/mule-2.3.tar.gz"
fi

echo "=== 検査を走らせる ==="
$SSH "sh /tmp/.github/ci/verify-mule.sh '$OPTS'"
