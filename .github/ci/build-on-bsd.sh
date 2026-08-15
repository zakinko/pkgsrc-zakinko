#!/bin/sh
# FreeBSD / OpenBSD / DragonFly の中で走る。pkgsrc を bootstrap して、
# この repo を zakinko カテゴリとして重ね、verify-mule.sh に渡す。
#
#   sh build-on-bsd.sh "<PKG_OPTIONS.mule>"
#
# NetBSD 側 (run-in-qemu.sh) と違うのは二点。pkgsrc が base に無いので
# bootstrap から始まること、そして公式のバイナリパッケージが配られて
# いないので依存を全部その場で組むこと。makeinfo のために perl まで
# 引くので、素で回すと 1 時間近くかかる。
#
# そこで bootstrap の binary kit と、作ったバイナリパッケージと配布物を
# workspace の .bsdcache に残す。VM は使い捨てだが、この下は rsync で
# host に戻って actions/cache に載るので、二度目からはそこを飛ばせる。
#
# 検査そのものは NetBSD と同じ verify-mule.sh を使う。同じものを二つ
# 書くと、必ず片方だけが古くなる。

set -e

OPTS=${1:-"-canna -wnn4 -x11"}
WS=$(cd "$(dirname "$0")/../.." && pwd)
OS=$(uname -s)
CACHE=$WS/.bsdcache/$OS
PKGSRC_URL=${PKGSRC_URL:-http://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz}

PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/pkg/bin:/usr/pkg/sbin:/usr/local/bin
export PATH

# どこまで進んだかを、転けたときに一行で言う。configure が unported で
# 止まったのか、依存の途中で転けたのか、ダンプが落ちたのかで次にやる
# ことが違う。
STAGE=開始
stage() { STAGE=$1; echo; echo "=== $STAGE ==="; }
report() {
	rc=$?
	[ $rc -eq 0 ] || echo "=== ここで止まった: $STAGE (exit=$rc) ==="
	exit $rc
}
trap report EXIT

# 取得の道具は OS ごとに違う。base にあるもので済ませる。
dl() {
	if command -v curl > /dev/null 2>&1; then curl -fsSL -o "$2" "$1"
	elif command -v fetch > /dev/null 2>&1; then fetch -q -o "$2" "$1"
	else ftp -o "$2" "$1"
	fi
}

echo "=== $OS $(uname -r) / $(uname -m) / PKG_OPTIONS.mule=\"$OPTS\" ==="
cc --version 2>/dev/null | head -1

# ------------------------------------------------------------------
stage "置き場所を決める"
# OpenBSD は既定で /usr や /home を別区画に切って入る。pkgsrc のツリー
# だけで 1.3GB、それに WRKOBJDIR が乗るので、/usr に置くと途中で
# ENOSPC になる。一番空いている区画にツリーと作業場所を置いて、
# /usr/pkgsrc からはそこへ symlink を張る。
#
# /usr/pkg のほうは動かさない。symlink 越しに binary kit を展開すると、
# tar の実装によっては symlink を消して実ディレクトリを作ってしまう。
# 前提を増やすより、狭ければ狭いと分かるほうがよい。
df -h
BIG=$(df -k | awk '
	NR > 1 && NF >= 6 {
		mp = $NF
		if (mp == "/dev" || mp == "/proc" || mp == "/tmp") next
		if ($(NF - 2) + 0 > max) { max = $(NF - 2) + 0; best = mp }
	}
	END { print best }')
[ -n "$BIG" ] || BIG=/
REAL=$BIG/pkgsrc-ci
echo "ツリーと作業場所は $REAL に置く"

mkdir -p "$REAL" "$REAL/obj" "$CACHE/distfiles" "$CACHE/packages"
if [ -d /usr/pkgsrc ] && [ ! -h /usr/pkgsrc ]; then
	# 既に実体があるなら触らない
	TOP=/usr
else
	[ -h /usr/pkgsrc ] || ln -s "$REAL/pkgsrc" /usr/pkgsrc
	TOP=$REAL
fi

# ------------------------------------------------------------------
stage "pkgsrc のツリーを置く"
if [ ! -d /usr/pkgsrc/mk ]; then
	dl "$PKGSRC_URL" "$REAL/pkgsrc.tar.gz"
	# 書庫の頂上が pkgsrc/ なので、/usr/pkgsrc の指す先の親へ展開する。
	tar xzf "$REAL/pkgsrc.tar.gz" -C "$TOP"
	rm -f "$REAL/pkgsrc.tar.gz"
fi
# どの日のツリーかは、転けたときに効く。current は毎日動く。
echo "ツリー: $(ls -ld /usr/pkgsrc/mk/bsd.pkg.mk | awk '{ print $6, $7, $8 }')"

# ------------------------------------------------------------------
stage "bootstrap"
if [ -s "$CACHE/bootstrap-kit.tar.gz" ]; then
	echo "前回の binary kit を使う"
	tar xzpf "$CACHE/bootstrap-kit.tar.gz" -C /
elif [ ! -x /usr/pkg/bin/bmake ]; then
	cd /usr/pkgsrc/bootstrap
	./bootstrap \
		--workdir="$REAL/bootstrap-work" \
		--gzip-binary-kit="$CACHE/bootstrap-kit.tar.gz"
	rm -rf "$REAL/bootstrap-work"
fi
test -x /usr/pkg/bin/bmake || { echo "bmake が無い"; exit 1; }

# ------------------------------------------------------------------
stage "mk.conf を整える"
MKCONF=/usr/pkg/etc/mk.conf
[ -f "$MKCONF" ] || MKCONF=/etc/mk.conf
# 前の回の kit にも同じ追記が入っている。置き場所が今回と同じとは限らない
# ので、残しておかずに書き直す。
if grep -q '^# pkgsrc-zakinko CI' "$MKCONF" 2>/dev/null; then
	sed '/^# pkgsrc-zakinko CI$/,$d' "$MKCONF" > "$MKCONF.ci"
	mv "$MKCONF.ci" "$MKCONF"
fi
cat >> "$MKCONF" <<EOF
# pkgsrc-zakinko CI
# 配布物と作ったパッケージは host に持ち帰る。作業場所は一番広い区画へ。
DISTDIR=	$CACHE/distfiles
PACKAGES=	$CACHE/packages
WRKOBJDIR=	$REAL/obj
EOF
cat "$MKCONF"

# 手元に取ってある配布物を先に置く。KAIST の書庫は落ちていることがある。
if [ -s "$WS/distfiles/mule-2.3.tar.gz" ]; then
	cp "$WS/distfiles/mule-2.3.tar.gz" "$CACHE/distfiles/"
fi

# ------------------------------------------------------------------
stage "zakinko カテゴリを重ねる"
mkdir -p /usr/pkgsrc/zakinko/mule
printf '# $NetBSD$\nCOMMENT=\tLocal\nSUBDIR+=\tmule\n.include "../mk/misc/category.mk"\n' \
	> /usr/pkgsrc/zakinko/Makefile
cp -R "$WS/mule/." /usr/pkgsrc/zakinko/mule/

# ------------------------------------------------------------------
stage "前回作った依存を入れる"
# ここは当てにしない。ツリーは current を取るので、前回のツリーで作った
# ものが今日の要求と合わないことがある。合わなければ入らないだけで、
# pkgsrc が作り直す。
if [ -d "$CACHE/packages/All" ]; then
	PKG_PATH="$CACHE/packages/All"
	export PKG_PATH
	for f in "$CACHE"/packages/All/*.tgz; do
		[ -f "$f" ] || continue
		case $f in */mule-[0-9]*) continue ;; esac
		/usr/pkg/sbin/pkg_add -U "$f" > /dev/null 2>&1 || true
	done
	unset PKG_PATH
	/usr/pkg/sbin/pkg_info | sed 's/^/    /'
fi

# ------------------------------------------------------------------
# あとは NetBSD と同じ。組んで、ダンプが生きているかまで見る。
stage "組んで確かめる"
sh "$WS/.github/ci/verify-mule.sh" "$OPTS"
