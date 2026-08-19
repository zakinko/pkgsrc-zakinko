#!/bin/sh
# netbsd-ci-images のイメージを QEMU で起動し、その中で組んで検査を走らせる。
# GitHub Actions の Linux runner で動かす。
#
#   sh run-in-qemu.sh <arch>-<release> "<PKG_OPTIONS.mule>"
#   例: sh run-in-qemu.sh i386-11.0 "canna wnn4 x11"
#
# 一つの package だけを見たいときは環境変数で渡す。mule の一式は作らず、
# 検査だけを送り込んで走らせる。
#
#   UPSTREAM_PKG=inputmethod/uim VERIFY_SCRIPT=verify-uim.sh \
#       sh run-in-qemu.sh amd64-10.1
#
# 上流の package はツリーにあるのでそのまま見る。こちらが手を入れたものは
# zakinko/<pkg> を渡すと、その一つだけをゲストのツリーへ置いてから見る。
#
#   UPSTREAM_PKG=zakinko/fail2ban sh run-in-qemu.sh amd64-10.1
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
# ツリーの出どころ。既定は current だが、公式のバイナリパッケージと版を
# 合わせたいときは四半期枝を指す。合わせておくと依存を bin-install で
# 引けるので、uim のように依存の山が高い相手が現実的な時間で終わる。
PKGSRC_URL=${PKGSRC_URL:-http://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz}
echo "ツリー: $PKGSRC_URL"

$SSH "PKGSRC_URL='$PKGSRC_URL' sh -s" <<'GUEST'
set -e
PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/pkg/bin:/usr/pkg/sbin
export PATH
if [ ! -d /usr/pkgsrc/mk ]; then
	ftp -o /tmp/pkgsrc.tar.gz "$PKGSRC_URL"
	tar xzf /tmp/pkgsrc.tar.gz -C /usr
	rm -f /tmp/pkgsrc.tar.gz
fi
mkdir -p /usr/pkgsrc/distfiles

# cdn の current/pkgsrc.tar.gz は日ごとに作り直されるわけではなく、
# 2026-08-17 の時点で 2026-08-15 01:18 UTC 版で止まっている。その版は
# fonts/fontconfig/Makefile rev 1.142 (2026-08-14 14:01 adam,
# 「since it uses meson, autoconf stuff is unnecessary」) を抱えていて、
# あの commit は pre-configure の行から先頭の - を落としてしまっている。
#
#	pre-configure:
#		cd ${BUILDLINK_X11_DIR} && ${FIND} . -path "*fontconfig*" ...
#
# X11_TYPE=native で .x11-buildlink が作られない相手だと
#
#	cd: can't cd to .../work/.x11-buildlink
#	*** Error code 2
#
# で止まる。- があれば無視される行なので、これは意図しない取りこぼしで
# ある。上流は rev 1.143 (2026-08-17 01:30 pgoyette「Unbreak the build」)
# で戻したが、スナップショットがまだ追いついていない。
#
# 同じ一文字を当てる。追いついたら grep が外れて何もしない。
FC=/usr/pkgsrc/fonts/fontconfig/Makefile
if [ -f "$FC" ] && ! grep -q -- '-cd ${BUILDLINK_X11_DIR}' "$FC" &&
   grep -q 'cd ${BUILDLINK_X11_DIR}' "$FC"; then
	sed 's|cd ${BUILDLINK_X11_DIR}|-cd ${BUILDLINK_X11_DIR}|' "$FC" > "$FC.new" &&
		mv "$FC.new" "$FC"
	echo "fontconfig: pre-configure の - を戻した (上流 rev 1.143 と同じ)"
fi
GUEST

if [ -n "${UPSTREAM_PKG:-}" ]; then
	# 上流の package を見る。zakinko カテゴリは要らない。
	VERIFY_SCRIPT=${VERIFY_SCRIPT:-verify-pkg.sh}
	case $UPSTREAM_PKG in
	zakinko/*)
		# こちらが手を入れたもの。その package だけを送り、ゲストの
		# ツリーの zakinko カテゴリに置く。カテゴリの Makefile は要らない。
		# 名指しで組むだけで、SUBDIR から辿ることはないため。
		P=${UPSTREAM_PKG#zakinko/}
		echo "=== 検査と $UPSTREAM_PKG を送り込む ==="
		tar czf - -C "$TREE" .github/ci "$P" | $SSH "tar xzf - -C /tmp"
		$SSH "mkdir -p /usr/pkgsrc/zakinko && cp -R /tmp/$P /usr/pkgsrc/zakinko/"
		;;
	*)
		# 素の上流。ツリーに在るものをそのまま見る。
		echo "=== 検査を送り込む ($UPSTREAM_PKG) ==="
		tar czf - -C "$TREE" .github/ci | $SSH "tar xzf - -C /tmp"
		;;
	esac

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
