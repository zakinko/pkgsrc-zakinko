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

# 置き場所。Darwin だけは /usr が読めるだけで書けない (SIP) ので、prefix も
# ツリーも /opt 側へ寄せる。pkgsrc の Darwin での慣例も /opt/pkg なので、
# 特別扱いというより本来の姿。他は従来どおり /usr/pkg と /usr/pkgsrc。
case $OS in
Darwin)	PREFIX=${PREFIX:-/opt/pkg} ;;
Haiku)	# Haiku に /usr は無い。書ける場所は /boot/home の下。
	PREFIX=${PREFIX:-/boot/home/pkg} ;;
*)	PREFIX=${PREFIX:-/usr/pkg} ;;
esac
export PREFIX

PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin:/usr/local/bin
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

# illumos の base の tar は pax 拡張ヘッダ (typeflag 'x') を知らない。
# pkgsrc.tar.gz は 100 字を超える patch 名にそれを使っているので、素の tar
# だと「typeflag 'x' not recognized」を数百行吐いた上で非零を返し、set -e で
# ここで止まる。警告を握り潰しても、長い名前が化けたツリーが残るだけで
# 意味がない。GNU tar があればそちらを使う。
TAR=tar
for t in gtar gnutar; do
	if command -v $t > /dev/null 2>&1; then TAR=$t; break; fi
done
[ "$TAR" = tar ] || echo "tar は $TAR を使う"

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
if [ "$OS" = Darwin ] || [ "$OS" = Haiku ]; then
	# /usr に symlink を張れない (Darwin は SIP、Haiku には /usr が無い)
	# ので、ツリーは置いた場所のまま使う。
	# pkgsrc は /usr/pkgsrc に居ることを要求しない。カテゴリの Makefile が
	# ../mk/misc/category.mk を読めればよく、それは相対で足りる。
	TREE=$REAL/pkgsrc
	TOP=$REAL
elif [ -d /usr/pkgsrc ] && [ ! -h /usr/pkgsrc ]; then
	# 既に実体があるなら触らない
	TREE=/usr/pkgsrc
	TOP=/usr
else
	[ -h /usr/pkgsrc ] || ln -s "$REAL/pkgsrc" /usr/pkgsrc
	TREE=/usr/pkgsrc
	TOP=$REAL
fi
export TREE
echo "ツリーは $TREE、prefix は $PREFIX"

# ------------------------------------------------------------------
stage "pkgsrc のツリーを置く"
if [ ! -d "$TREE/mk" ]; then
	dl "$PKGSRC_URL" "$REAL/pkgsrc.tar.gz"
	# 書庫の頂上が pkgsrc/ なので、/usr/pkgsrc の指す先の親へ展開する。
	$TAR xzf "$REAL/pkgsrc.tar.gz" -C "$TOP"
	rm -f "$REAL/pkgsrc.tar.gz"
fi
# どの日のツリーかは、転けたときに効く。current は毎日動く。
echo "ツリー: $(ls -ld "$TREE/mk/bsd.pkg.mk" | awk '{ print $6, $7, $8 }')"

# ------------------------------------------------------------------
stage "bootstrap"
if [ -s "$CACHE/bootstrap-kit.tar.gz" ]; then
	echo "前回の binary kit を使う"
	$TAR xzpf "$CACHE/bootstrap-kit.tar.gz" -C /
elif [ ! -x "$PREFIX/bin/bmake" ]; then
	# bootstrap は workdir が既にあると何もせず終わる (README に
	# 「あるなら ./cleanup しろ」と書いてある)。前回の失敗が残っている
	# ことがあるので、こちらで消してから入る。
	rm -rf "$REAL/bootstrap-work"

	# 何コアあるかは OS で訊き方が違う。getconf はだいたいどこでも動く。
	JOBS=$(getconf _NPROCESSORS_ONLN 2>/dev/null ||
	       sysctl -n hw.ncpu 2>/dev/null || echo 1)

	# illumos と Solaris は 32bit で bootstrap されるのが既定。せっかく
	# 64bit の機械なので合わせる。他は既定のままにする。
	case $OS in
	SunOS)	ABI="--abi 64" ;;
	*)	ABI= ;;
	esac

	cd "$TREE/bootstrap"
	./bootstrap \
		--prefix="$PREFIX" \
		--workdir="$REAL/bootstrap-work" \
		--make-jobs "$JOBS" \
		$ABI \
		--gzip-binary-kit="$CACHE/bootstrap-kit.tar.gz"
	rm -rf "$REAL/bootstrap-work"
fi
test -x "$PREFIX/bin/bmake" || { echo "bmake が無い"; exit 1; }

# ------------------------------------------------------------------
stage "mk.conf を整える"
MKCONF=$PREFIX/etc/mk.conf
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
# runner に IPv6 の経路が無い。AAAA を先に引きに行くと一つ 75 秒待たされる。
# mk/fetch/fetch.mk が ftp に -4 を、curl に --ipv4 を渡す。
FETCH_USE_IPV4_ONLY=	yes
EOF
cat "$MKCONF"

# 手元に取ってある配布物を先に置く。KAIST の書庫は落ちていることがある。
if [ -s "$WS/distfiles/mule-2.3.tar.gz" ]; then
	cp "$WS/distfiles/mule-2.3.tar.gz" "$CACHE/distfiles/"
fi

# ------------------------------------------------------------------
stage "zakinko カテゴリを重ねる"
# 何を組むかは PKGS で渡す。既定は mule2 (Mule 2.3) だけ。8d71ae8 で
# mule という名前は Mule 1.1 に移ったので、既定のままだと 2.3 の検査を
# 名乗る job が 1.1 を組むことになる。空白区切りで並べれば、
# この repo のパッケージをまとめて回せる。
#
# :- ではなく - なのは、PKGS='' を「既定に戻せ」ではなく「zakinko からは
# 何も組むな」と読ませたいため。
PKGS=${PKGS-mule2}
# 建てずに連れていくだけのもの。emacs28-nox11 は emacs28 の Makefile.common と
# PLIST と patches と files を読むが、emacs28 そのもの (X 版) を建てる必要は
# ない。PKGS に並べると建ててしまうので、口を分ける。SUBDIR にも入れない。
CARRY=${CARRY-}
mkdir -p "$TREE/zakinko"
{
	printf '# $NetBSD$\nCOMMENT=\tLocal\n'
	for p in $PKGS; do printf 'SUBDIR+=\t%s\n' "$p"; done
	printf '.include "../mk/misc/category.mk"\n'
} > "$TREE/zakinko/Makefile"
for p in $PKGS $CARRY; do
	[ -d "$WS/$p" ] || { echo "!! $p が repo に無い" >&2; continue; }
	mkdir -p "$TREE/zakinko/$p"
	cp -R "$WS/$p/." "$TREE/zakinko/$p/"
	echo "    $p"
done

# ------------------------------------------------------------------
stage "前回作った依存を入れる"
# ここは当てにしない。ツリーは current を取るので、前回のツリーで作った
# ものが今日の要求と合わないことがある。合わなければ入らないだけで、
# pkgsrc が作り直す。
if [ -d "$CACHE/packages/All" ]; then
	PKG_PATH="$CACHE/packages/All"
	export PKG_PATH
	# 検査する当人は戻さない。組み直したものと取り違えるため。名前を
	# 直書きすると 8d71ae8 のような改名で網から漏れる (2.3 が mule2-*.tgz に
	# なった時点で */mule-[0-9]* には当たらなくなった)。しかもその漏れは
	# その場で転ばず、緑のまま古いものを検査する形で出る。PKGS から組み立てる。
	for f in "$CACHE"/packages/All/*.tgz; do
		[ -f "$f" ] || continue
		skip=no
		for p in $PKGS; do
			case $(basename "$f") in
			"$p"-[0-9]*) skip=yes ;;
			esac
		done
		[ "$skip" = yes ] && continue
		$PREFIX/sbin/pkg_add -U "$f" > /dev/null 2>&1 || true
	done
	unset PKG_PATH
	$PREFIX/sbin/pkg_info | sed 's/^/    /'
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
	if [ "${VERIFY:-full}" != basic ] && [ -f "$WS/.github/ci/verify-$p.sh" ]; then
		sh "$WS/.github/ci/verify-$p.sh" "$OPTS" || rc=1
	else
		sh "$WS/.github/ci/verify-pkg.sh" "$p" || rc=1
	fi
done

# 上流ツリーのパッケージを名指しで組みたいときの口。TREE_PKGS に
# <カテゴリ>/<パッケージ> を並べる。zakinko/ の写しではなく素の pkgsrc が
# どうなるかを見るのに使う (anthy-linux.yml の「当て物なし」がこれ)。
#
# 検査は名前で引く。verify-<パッケージ名>.sh があればそれを、無ければ
# verify-pkg.sh は使えない (あちらは zakinko/ 配下を見る) ので、組めた
# かどうかだけを見て終わる。
for p in ${TREE_PKGS:-}; do
	echo
	echo "########## $p (上流ツリー) ##########"
	n=${p##*/}
	if [ -f "$WS/.github/ci/verify-$n.sh" ]; then
		sh "$WS/.github/ci/verify-$n.sh" "$p" || rc=1
	elif [ -d "$TREE/$p" ]; then
		( cd "$TREE/$p" && "$PREFIX/bin/bmake" install ) || rc=1
	else
		echo "!! $p が pkgsrc に無い" >&2
		rc=1
	fi
done

[ $rc -eq 0 ] || { echo "=== 通らなかったものがある ==="; exit 1; }
