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

# Solaris と illumos は gcc を /usr/gcc/<版>/bin に置き、/usr/bin/gcc は
# mediator が張られたときだけ現れる。張られていない箱では bootstrap の
# bmake の configure が "no acceptable C compiler found in $PATH" で止まり、
# 「この platform は unported」に見えてしまう。cc も gcc も見えないときだけ
# 足すので、箱が既に持っているものは動かさない。
if [ "$(uname -s)" = SunOS ] && ! command -v cc >/dev/null 2>&1 &&
   ! command -v gcc >/dev/null 2>&1; then
	for _d in /usr/gcc/*/bin /opt/gcc-*/bin /opt/csw/bin; do
		if [ -x "$_d/gcc" ]; then
			PATH=$_d:$PATH; export PATH
			echo "  cc が無いので $_d を PATH に足した: $(gcc --version 2>&1 | head -1)"
			break
		fi
	done
	command -v gcc >/dev/null 2>&1 ||
		echo "  !! gcc が見付からない。/usr/gcc と /opt にも無い" >&2
fi

# どこまで進んだかを、転けたときに一行で言う。configure が unported で
# 止まったのか、依存の途中で転けたのか、ダンプが落ちたのかで次にやる
# ことが違う。
STAGE=開始
stage() { STAGE=$1; echo; echo "=== $STAGE ==="; }
report() {
	rc=$?
	# OpenBSD では devel/ncurses の configure (CF_LD_SEARCHPATH) が
	# `ldconfig -v` を走らせる。Linux では一覧を出すだけの命令だが、
	# OpenBSD の -v は /var/run/ld.so.hints を既定の /usr/lib だけで
	# 書き直してしまい、/usr/local の binary が全部 library を見失う。
	# この job では成功した直後の copyback の rsync が
	# `ld.so: rsync: can't load library 'liblz4.so.3.3'` で Killed になり、
	# 緑の建ちが赤い job として出ていた。rc と同じ一覧で貼り直す。
	if [ "$(uname -s)" = OpenBSD ]; then
		_sd=$(ldconfig -r 2>/dev/null |
			sed -n 's/^[[:space:]]*search directories:[[:space:]]*//p')
		echo "  ld.so.hints の search directories: ${_sd:-(読めない)}"
		case $_sd in
		*/usr/local/lib*)
			echo "  hints は無事 (ncurses の当て物が効いている)" ;;
		*)
			echo "  !! hints が /usr/lib だけになっている。貼り直す"
			ldconfig /usr/local/lib /usr/X11R6/lib 2>&1 |
				sed 's/^/  ldconfig: /' || true ;;
		esac
	fi
	[ $rc -eq 0 ] || {
		echo "=== ここで止まった: $STAGE (exit=$rc) ==="
		# lib-src/Makefile と src/Makefile は Makefile.in.in を system の
		# cpp に通して作る。cpp が違えば出来る物も違い、make が読めない形に
		# なる箱がある。行番号だけ言われても手元では再現しないので、
		# 落ちたときは実物を出す。TAB が見えないと意味がないので cat -t。
		for m in "$REAL"/obj/zakinko/mule*/work/mule/lib-src/Makefile \
			 "$REAL"/obj/zakinko/mule*/work/mule/src/Makefile; do
			[ -f "$m" ] || continue
			echo "--- $m の 100-135 行 ---"
			sed -n '100,135p' "$m" | cat -t 2>/dev/null ||
				sed -n '100,135p' "$m"
		done
		# temacs や emacs が落ちると BSD は cwd に <名前>.core を置く。
		# DragonFly は temacs が mule-inst.el を読む所で黙って abort し、
		# log には "Abort trap (core dumped)" の一行しか残らなかった。
		# core が在れば gdb に食わせる。gdb の無い箱では何も出ない。
		for c in "$REAL"/obj/zakinko/mule*/work/mule/src/*.core; do
			[ -f "$c" ] || continue
			b=${c%.core}
			[ -x "$b" ] || continue
			echo "--- $c ---"
			for g in gdb egdb; do
				command -v $g > /dev/null 2>&1 || continue
				$g -batch -ex 'bt 25' "$b" "$c" 2>&1 | head -40
				break
			done
		done
	}
	exit $rc
}
trap report EXIT

# 取得の道具は OS ごとに違う。base にあるもので済ませる。
#
# 三度まで撃ち直す。pkgsrc.tar.gz (140MB) の取得が
#
#	curl: (18) end of response with 100074830 bytes missing
#
# で切れて OpenIndiana の測定が丸ごと流れた。18 は CURLE_PARTIAL_FILE で、
# 箱の側の問題ではない。
#
# curl の --retry は足さない。古い箱の curl が知らない option を渡すと
# unknown option で即死し、一時的な失敗を直すために恒久的な失敗を作る。
# 外側で回すだけなら、どの道具でも同じように効く。
#
# 撃ち直す前に取れかけの file を消す。残すと、続きから取ったように見えて
# 壊れた物が通ることがある。
dl() {
	_u=$1; _o=$2; _n=0
	while :; do
		_n=$((_n + 1))
		if command -v curl > /dev/null 2>&1; then
			curl -fsSL -o "$_o" "$_u" && return 0
		elif command -v fetch > /dev/null 2>&1; then
			fetch -q -o "$_o" "$_u" && return 0
		else
			ftp -o "$_o" "$_u" && return 0
		fi
		if [ "$_n" -ge 3 ]; then
			echo "!! $_u を三度試して取れなかった" >&2
			return 1
		fi
		echo "  取得が失敗した ($_n 回目)。5 秒待って撃ち直す: $_u" >&2
		rm -f "$_o"
		sleep 5
	done
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
# この箱の grep が BRE の何を解すかを印字する。信念ではなく数字で残す。
#
# peer (netbsd-zfs-4c) が techne で実測して、そこでは \| は解されるが \s は
# 解されないと報せてきた。つまり「BSD だから \| が駄目」は箱によって外れる。
# どの箱で何が生きているかを言えるようにしておく。
#
# 直し方は箱に依らず -E なので、この数字で分岐はしない。読むためだけに出す。
stage "この箱の grep が解す escape"
# 版も出す。手元の macOS は "BSD grep, GNU compatible 2.6.0-FreeBSD" で
# \d まで全部解し、techne の NetBSD は \| は解すが \s は解さない。
# 「BSD だから」では括れないので、記録が自分で説明できるようにしておく。
echo "    grep: $(command -v grep)"
echo "    $(grep --version 2>&1 | head -1)"
for _e in '\|' '\s' '\+' '\?' '\d' '\w'; do
	# a と b を繋いだ pattern が両方に当たるかで見る。解さなければ
	# literal として扱われ、どちらにも当たらない。
	case $_e in
	'\|')	_p='a\|b'; _in='a' ;;
	'\s')	_p='a\sb'; _in='a b' ;;
	'\+')	_p='ab\+'; _in='abb' ;;
	'\?')	_p='ab\?c'; _in='ac' ;;
	'\d')	_p='a\db'; _in='a1b' ;;
	'\w')	_p='a\wb'; _in='axb' ;;
	esac
	if printf '%s\n' "$_in" | grep -q "$_p" 2>/dev/null; then
		echo "    $_e  解す"
	else
		echo "    $_e  解さない  (この箱では grep -q '$_p' が常に偽)"
	fi
done
echo "    -> 直し方は箱に依らず grep -E と | / [[:space:]]"

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

# 本家の木そのものに手を入れたいときの口。上流の bug を直して、その直しが
# 効くかをここで測るのに使う。TREE_PATCH を設定しなければ何もしない。
# 空白で区切って複数書ける。書いた順に当たる。
if [ -n "${TREE_PATCH:-}" ]; then
	stage "ツリーに当て物をする ($TREE_PATCH)"
	for _p in $TREE_PATCH; do
		[ -f "$WS/$_p" ] || {
			echo "!! TREE_PATCH=$_p が repo に無い" >&2; exit 1; }
		sh "$WS/$_p" "$TREE" || exit 1
	done
fi

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
# 依存も package にする。PACKAGES を指しているだけでは All/ は空のままで、
# 素の bmake install だと mk/depends/bsd.depends.mk の
#     .else
#     DEPENDS_TARGET=	reinstall
#     .endif
# に落ちるので、依存は入るだけで .tgz が残らない。TCG の箱では 61 package
# まで建てた所で job の timeout に当たっており、その分が毎回まるごと
# 捨てられていた。package-install にすれば建てた端から All/ に積まれ、
# 次の run が続きから始められる。
DEPENDS_TARGET=	package-install
EOF
# job ごとの追記。改行区切りでそのまま足す。OpenBSD の croc が
# GOROOT_BOOTSTRAP をここから渡す。
if [ -n "${MKCONF_EXTRA:-}" ]; then
	printf '%s\n' "$MKCONF_EXTRA" >> "$MKCONF"
fi
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
# 走る時間に上限を持たせる。job の timeout は「cancel」なので
# actions/cache の save が走らない。実際 FreeBSD aarch64 の log には
# restore の "Cache not found for input keys: gobin-..." は在るのに
# "Cache saved: gobin-..." が一度も無く、post step は checkout の分しか
# 走っていなかった。自分から降りれば job は「失敗」で終わり、失敗なら
# post step は走るので、建てた分が次の run に渡る。
#
# BUILD_DEADLINE は timeout(1) に渡す値 (例 300m)。timeout(1) が無い箱では
# 上限なしで走る。そこは今までと同じ。
#
# 定義はここ、PKGS の輪の前に置く。最初は TREE_PKGS の輪の直前に置いていて、
# **PKGS の輪には一度も掛かっていなかった。**go-bin は PKGS なので、期限は
# 効かず OpenBSD の二箱は 350 分の job timeout に当たって cancel され、cache も
# 残らなかった。効いているつもりで効いていない仕掛けだった。
DEADLINE_HIT=0
# 期限は **この script が始まった時点から** 数える。最初は timeout に
# BUILD_DEADLINE をそのまま渡していたが、timeout はその呼び出しの時点から
# 数えるので、VM の起動と木の取得と bootstrap に使った分が期限の外に出る。
# bootstrap が一時間かかれば 320m の期限は t=380 分になり、job の 350 分を
# 超えて一度も鳴らない。実際 FreeBSD aarch64 と OpenBSD の二箱は三度とも
# ちょうど 350 分で cancel され、期限の文言は出ていなかった。
_T0=$(date +%s 2>/dev/null || echo 0)
# BUILD_DEADLINE は 320m のような形で来る。秒に直す。
_deadline_secs() {
	case ${BUILD_DEADLINE:-} in
	*m)	echo $(( ${BUILD_DEADLINE%m} * 60 )) ;;
	*h)	echo $(( ${BUILD_DEADLINE%h} * 3600 )) ;;
	*s)	echo "${BUILD_DEADLINE%s}" ;;
	"")	echo 0 ;;
	*)	echo "$BUILD_DEADLINE" ;;
	esac
}
run_bounded() {
	if [ -n "${BUILD_DEADLINE:-}" ] && command -v timeout > /dev/null 2>&1 &&
	   [ "$_T0" != 0 ]; then
		_tot=$(_deadline_secs)
		_now=$(date +%s)
		_left=$(( _tot - (_now - _T0) ))
		if [ "$_left" -le 60 ]; then
			echo "  !! 期限 $BUILD_DEADLINE のうち残り ${_left}s。始めずに降りる" >&2
			DEADLINE_HIT=1
			return 124
		fi
		echo "  (期限まで残り $(( _left / 60 )) 分)"
		timeout "${_left}s" "$@"
		_r=$?
		# GNU/BSD の timeout はどちらも期限切れを 124 で返す。
		if [ "$_r" -eq 124 ]; then
			echo "  !! 期限 $BUILD_DEADLINE に達した。ここまでを cache に残して降りる" >&2
			DEADLINE_HIT=1
		fi
		return "$_r"
	fi
	"$@"
}

for p in $PKGS; do
	# 一つが期限を使い切ったら残りは始めない。
	[ "$DEADLINE_HIT" = 1 ] && { echo "  (期限切れのため $p は始めない)"; rc=1; continue; }
	echo
	echo "########## $p ##########"
	if [ "${VERIFY:-full}" != basic ] && [ -f "$WS/.github/ci/verify-$p.sh" ]; then
		run_bounded sh "$WS/.github/ci/verify-$p.sh" "$OPTS" || rc=1
	else
		run_bounded sh "$WS/.github/ci/verify-pkg.sh" "$p" || rc=1
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
	# 一つが期限を使い切ったら残りは始めない。始めると次の run で
	# 何が済んでいるのかが読めなくなる。
	[ "$DEADLINE_HIT" = 1 ] && { echo "  (期限切れのため $p は始めない)"; rc=1; continue; }
	echo
	echo "########## $p (上流ツリー) ##########"
	n=${p##*/}
	if [ -f "$WS/.github/ci/verify-$n.sh" ]; then
		run_bounded sh "$WS/.github/ci/verify-$n.sh" "$p" || rc=1
	elif [ -d "$TREE/$p" ]; then
		run_bounded sh -c 'cd "$1" && "$2" install' _ "$TREE/$p" "$PREFIX/bin/bmake" || rc=1
	else
		echo "!! $p が pkgsrc に無い" >&2
		rc=1
	fi
done

if [ "$DEADLINE_HIT" = 1 ]; then
	echo "=== 期限で降りた。緑ではない。cache は残したので次の run が続きから ==="
	ls "$CACHE"/packages/All/*.tgz 2>/dev/null | wc -l | sed 's/^/    All\/ の .tgz: /'
	exit 1
fi
[ $rc -eq 0 ] || { echo "=== 通らなかったものがある ==="; exit 1; }
