#!/bin/sh
# NetBSD 以外の pkgsrc プラットフォームの中で走る。pkgsrc を bootstrap
# して、この repo を zakinko カテゴリとして重ね、verify-mule.sh に渡す。
#
#   sh build-on-bsd.sh "<PKG_OPTIONS.mule>"
#
# 名前は BSD だが、中身は OPSYS を選ばない。Darwin と Linux の native
# runner からも同じものを呼んでいる。そちらは root で走らないので、
# 呼ぶ側が sudo と PKGSRC_BASE を渡す。
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
# キャッシュは機種ごとに分ける。同じ FreeBSD でも amd64 と i386 では
# バイナリパッケージも bootstrap kit も混ぜられない。
CACHE=$WS/.bsdcache/$OS-$(uname -m)
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
if [ -n "${PKGSRC_BASE:-}" ]; then
	# native runner (Darwin と Linux) はここを渡してくる。区画は一つで、
	# しかも df の桁が BSD と違う (macOS は inode の欄が three つ余計に
	# 並ぶ) ので、選ばせずに決め打ちする。
	BIG=$PKGSRC_BASE
else
BIG=$(df -k | awk '
	NR > 1 && NF >= 6 {
		mp = $NF
		if (mp == "/dev" || mp == "/proc" || mp == "/tmp") next
		if ($(NF - 2) + 0 > max) { max = $(NF - 2) + 0; best = mp }
	}
	END { print best }')
fi
[ -n "$BIG" ] || BIG=/
# 一番空いているのが / だと、素直に繋ぐと //pkgsrc-ci になる。bootstrap は
# --workdir が canonical でないと受け付けない。
REAL=${BIG%/}/pkgsrc-ci
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
# 何を組むかは PKGS で渡す。既定は mule だけ。空白区切りで並べれば、
# この repo のパッケージをまとめて回せる。
PKGS=${PKGS:-mule}
{
	printf '# $NetBSD$\nCOMMENT=\tLocal\n'
	for p in $PKGS; do printf 'SUBDIR+=\t%s\n' "$p"; done
	printf '.include "../mk/misc/category.mk"\n'
} > /usr/pkgsrc/zakinko/Makefile
for p in $PKGS; do
	[ -d "$WS/$p" ] || { echo "!! $p が repo に無い" >&2; continue; }
	mkdir -p "/usr/pkgsrc/zakinko/$p"
	cp -R "$WS/$p/." "/usr/pkgsrc/zakinko/$p/"
	echo "    $p"
done

# ------------------------------------------------------------------
stage "overlay を上流のカテゴリへ重ねる"
# overlay/ は自作パッケージではなく、上流 pkgsrc の package への当て物。
# NetBSD 側は NetBSD-i386 の ci/make-pkgsrc-tarball.sh がツリーへ焼き込んで
# 渡してくるが、こちらはツリーをその場で展開するので、ここで当てる。
#
# 当てないと DragonFly は mule に届かない。依存の devel/libuuid が
# そのままでは組めず、lang/python313 から gtexinfo までが全部止まる。
NEEDSUM=
for d in $(cd "$WS/overlay" && find . -mindepth 2 -maxdepth 2 -type d |
           sed 's|^\./||' | sort); do
	if [ ! -d "/usr/pkgsrc/$d" ]; then
		echo "!! overlay: $d が pkgsrc に無い。飛ばす。" >&2
		continue
	fi
	( cd "$WS/overlay/$d" && tar cf - . ) | ( cd "/usr/pkgsrc/$d" && tar xf - )
	echo "    $d"
	if [ -d "$WS/overlay/$d/patches" ]; then
		NEEDSUM="$NEEDSUM $d"
	fi
done

# patch を足したものは distinfo に SHA1 が要る。makepatchsum は
# pkgtools/digest の digest を呼び、無いと黙って何も書かずに成功する。
if [ -n "$NEEDSUM" ]; then
	if [ ! -x /usr/pkg/bin/digest ]; then
		( cd /usr/pkgsrc/pkgtools/digest && bmake install ) ||
		    echo "!! pkgtools/digest が入らない" >&2
	fi
	for d in $NEEDSUM; do
		# ここで転けても止めない。mule の依存にはこれらは入って
		# いないので、distinfo が古いままでも今回のビルドには効かない。
		# 万一入ったときは patch のチェックサム不一致で必ず止まる。
		( cd "/usr/pkgsrc/$d" && bmake makepatchsum ) ||
		    echo "!! $d の makepatchsum に失敗" >&2
	done
fi

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
# あとは NetBSD と同じ。パッケージごとに、専用の検査があればそれを、
# 無ければ組んで入るところまでを見る。
#
# 一つ転けてもそこで止めない。三つのうちどれが通ってどれが駄目かを、
# 一回の実行で知りたい。
stage "組んで確かめる"
rc=0
for p in $PKGS; do
	echo
	echo "########## $p ##########"
	if [ -f "$WS/.github/ci/verify-$p.sh" ]; then
		sh "$WS/.github/ci/verify-$p.sh" "$OPTS" || rc=1
	else
		sh "$WS/.github/ci/verify-pkg.sh" "$p" || rc=1
	fi
done
[ $rc -eq 0 ] || { echo "=== 通らなかったものがある ==="; exit 1; }
