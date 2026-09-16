#!/bin/sh
# net/croc を 11.5.3 へ上げる件を、建てて、入れて、実際に送受信して見る。
#
#   sh verify-croc.sh [zakinko/croc]
#
# 11.3.3 で Tailscale を使う transport が tree 内に入り、tailscale.com を
# 引くようになった。上流は src/tailcattransport と src/sshshare の全 file に
#
#	//go:build !croc_no_tailcat && (linux || windows || darwin || freebsd || openbsd)
#
# を置いて、それ以外の OS では stub を選ぶ。それでも pkgsrc の go-module.mk は
# 既定で ./... を建てるので、main から誰も import しない internal/tailcat が
# それ自身 package として compile され、OS の tag を持たないそこが
#
#	imports github.com/tailscale/wireguard-go/ipc: build constraints exclude
#	    all Go files in .../wireguard-go@v0.0.0-20260715223240-2e01ba5b00f0/ipc
#
# で落ちる。NetBSD 11.0/amd64 (techne) で踏んだ。直しは上流の Makefile と同じ
# 二つだけを建てること。
#
#	GO_BUILD_PATTERN=	. ./cmd/croc-web
#
# 三段で見る。
#
#   1. zakinko/croc (pattern 入り) を install して package も作る。
#      bin/croc と bin/croc-web が入り、croc version が 11.5.3 と言うか。
#   2. 127.0.0.1 に relay を立て、300000 byte を send して receive する。
#      cksum が一致するか。code は CROC_SECRET で渡す (--code は classic mode
#      限定になった)。
#   3. 同じ木で GO_BUILD_PATTERN=./... に戻して build だけする。上流の tag の
#      一覧に入る OS (FreeBSD、Darwin、Linux、OpenBSD) では通り、入らない OS
#      (NetBSD、DragonFly) では落ちるはずである。どちらに出たかを記録する。
#      これは pattern が要る理由の裏で、通っても落ちても検査の成否には
#      入れない。

PKG=zakinko/croc
if [ -n "${1:-}" ] && [ -d "${TREE:-/usr/pkgsrc}/$1" ]; then
	PKG=$1
fi
OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
export PATH
unset PKG_PATH
T=${TMPDIR:-/tmp}

if [ -x "$PREFIX/bin/bmake" ]; then
	PKGMAKE=$PREFIX/bin/bmake
	MKARGS="DEPENDS_TARGET=bin-install"
	# 座標の組み立ては verify-xwpe.sh と同じ。四半期は固定で、末尾に /All
	# を付けない。木は current なので、版が噛み合う依存だけが binary から
	# 入り、go127 のように四半期に無いものは source から組まれる
	# (go127 は go124 から bootstrap し、go124 は四半期の集合に在る)。
	if [ "$OS" = NetBSD ] && [ -z "${BINPKG_SITES:-}" ]; then
		_rel=$(uname -r); _br=${_rel%%.*}.0
		BINPKG_SITES=http://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/$(uname -p)/${_br}_2026Q2
	fi
	if [ -n "${BINPKG_SITES:-}" ]; then
		MKARGS="$MKARGS BINPKG_SITES=$BINPKG_SITES"
		echo "--- 依存の出どころ: $BINPKG_SITES ---"
	else
		echo "--- 依存の出どころ: 無し。全部その場で組む ---"
	fi
elif [ "$OS" = NetBSD ]; then
	# base の make で済む NetBSD には bmake が無い。ここを MKARGS="" に
	# していたので、qemu の箱では依存を一つも降ろさず perl も python も
	# go14 から go127 までも source で組み、work が 11GB の disk を埋めて
	# go127 の go_bootstrap が exit status 1 で止まった (run 35092623482、
	# console に /var/log/messages: No space left on device)。bin-install は
	# source へ落ちた package を package-install && clean で片付けるので、
	# 上の枝と同じものを渡す。verify-xwpe.sh と同じ形。
	PKGMAKE=make
	MKARGS="DEPENDS_TARGET=bin-install"
	if [ -z "${BINPKG_SITES:-}" ]; then
		_rel=$(uname -r); _br=${_rel%%.*}.0
		BINPKG_SITES=http://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/$(uname -p)/${_br}_2026Q2
	fi
	MKARGS="$MKARGS BINPKG_SITES=$BINPKG_SITES"
	echo "--- 依存の出どころ: $BINPKG_SITES ---"
else
	PKGMAKE=make
	MKARGS=""
fi

cd "$TREE/$PKG" || { echo "FAIL: $TREE/$PKG が無い"; exit 1; }
rc=0
echo "--- $PKG ($OS $(uname -r) / $(uname -m)) ---"
grep -nE 'DISTNAME|GO_VERSION_REQD|GO_BUILD_PATTERN' Makefile | sed 's/^/  /'

echo
echo "########## 1. 建てて入れて package ##########"
$PKGMAKE clean > /dev/null 2>&1
if $PKGMAKE $MKARGS install > "$T/croc-install.log" 2>&1; then
	echo "  ok install"
else
	echo "FAIL: install が落ちた"; rc=1
	# どの依存の中で落ちたかが要る。checking や Checksum の行は捨てる。
	# 選択は -E の | で書く。BSD の grep は \| を解さないので、OpenBSD では
	# 三つの grep とも黙り、go120 で止まった理由が一行も残らなかった。
	echo "  -- 依存の連鎖"
	grep -nE '===> Installing dependencies for|NOT found' "$T/croc-install.log" | sed 's/^/     /'
	echo "  -- error らしい行"
	grep -nE 'constraints exclude|ERROR|error:|fatal|cannot|Cannot|No such|not supported|\*\*\* \[|No space|Killed|signal: ' "$T/croc-install.log" |
		grep -vE 'checking|Checksum|unused' | head -20 | sed 's/^/     /'
	echo "  -- 末尾"
	grep -vE 'Checksum|=> Fetching|^checking' "$T/croc-install.log" | tail -30 | sed 's/^/     /'
	df -h /usr 2>/dev/null | sed 's/^/     /'
fi
if [ $rc -eq 0 ]; then
	if $PKGMAKE $MKARGS package > "$T/croc-package.log" 2>&1; then
		echo "  ok package: $(ls "$($PKGMAKE show-var VARNAME=PKGFILE)" 2>/dev/null | sed 's|.*/||')"
	else
		echo "FAIL: package が落ちた"; rc=1; tail -15 "$T/croc-package.log"
	fi
	for b in croc croc-web; do
		[ -x "$PREFIX/bin/$b" ] && echo "  ok bin/$b" || { echo "!! bin/$b が無い"; rc=1; }
	done
	[ -e "$PREFIX/bin/install" ] && { echo "!! bin/install が入っている (./... の名残)"; rc=1; }
	_v=$("$PREFIX/bin/croc" --version 2>&1 | head -1)
	echo "  $_v"
	case $_v in *11.5.3*) : ;; *) echo "!! 版が違う"; rc=1 ;; esac
fi

echo
echo "########## 2. relay を立てて送受信 ##########"
if [ $rc -eq 0 ]; then
	D=$T/croc-run; rm -rf "$D"; mkdir -p "$D/send" "$D/recv" "$D/home"
	head -c 300000 /dev/urandom > "$D/send/payload.bin"
	_before=$(cksum < "$D/send/payload.bin")
	HOME=$D/home; export HOME
	"$PREFIX/bin/croc" relay --ports 19009,19010,19011 > "$D/relay.log" 2>&1 & RP=$!
	sleep 2
	(cd "$D/send" && CROC_SECRET=ci-539f6cf2-croc "$PREFIX/bin/croc" --relay 127.0.0.1:19009 \
		--overwrite send payload.bin > "$D/send.log" 2>&1) & SP=$!
	sleep 3
	(cd "$D/recv" && CROC_SECRET=ci-539f6cf2-croc "$PREFIX/bin/croc" --relay 127.0.0.1:19009 \
		--yes --overwrite > "$D/recv.log" 2>&1) & CP=$!
	n=0; while [ $n -lt 90 ] && kill -0 $CP 2>/dev/null; do sleep 1; n=$((n+1)); done
	kill -0 $CP 2>/dev/null && { echo "!! receiver が 90 秒で終わらない"; kill $CP; rc=1; }
	kill -0 $SP 2>/dev/null && { kill $SP; }
	kill $RP 2>/dev/null; sleep 1
	if [ -f "$D/recv/payload.bin" ]; then
		_after=$(cksum < "$D/recv/payload.bin")
		echo "  cksum: $_before -> $_after"
		[ "$_before" = "$_after" ] && echo "  ok 300000 byte が relay 越しに同じ中身で届いた" ||
			{ echo "!! 中身が違う"; rc=1; }
	else
		echo "!! 受け取った file が無い"; rc=1
		echo "  -- send.log"; tail -5 "$D/send.log"; echo "  -- recv.log"; tail -5 "$D/recv.log"
		echo "  -- relay.log"; tail -3 "$D/relay.log"
	fi
	ps -axo pid,command 2>/dev/null | grep "$PREFIX/bin/croc" | grep -v grep && echo "!! croc が残っている"
else
	echo "  (1 が落ちたので見ない)"
fi

echo
echo "########## 3. GO_BUILD_PATTERN=./... に戻したら ##########"
$PKGMAKE clean > /dev/null 2>&1
if $PKGMAKE $MKARGS GO_BUILD_PATTERN=./... build > "$T/croc-dotdotdot.log" 2>&1; then
	echo "  ./... でも建つ (この OS は上流の tag の一覧に入っている)"
else
	if grep -q 'build constraints exclude' "$T/croc-dotdotdot.log"; then
		echo "  ./... は落ちる (pattern が要る側の OS):"
		grep -nE 'constraints exclude|^package |imports ' "$T/croc-dotdotdot.log" | head -6 | sed 's/^/     /'
	else
		echo "  ./... は別の理由で落ちた:"
		grep -nE 'ERROR|error:|\*\*\* \[' "$T/croc-dotdotdot.log" | grep -vE 'checking|Checksum' | head -6 | sed 's/^/     /'
	fi
fi
$PKGMAKE clean > /dev/null 2>&1

echo
[ $rc -eq 0 ] && echo "RESULT: croc 11.5.3 は建って入って、relay 越しに送受信できる" \
	|| echo "RESULT: 通らなかったものがある (上を読む)"
exit $rc
