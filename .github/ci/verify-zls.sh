#!/bin/sh
# devel/zls の更新を、send-pr に書く主張ごとに測る。
#
#   sh verify-zls.sh <カテゴリ>/<パッケージ>
#
# 書こうとしている主張は三つある。読んだだけで書くと外すので、それぞれに
# 測る段を作る。
#
#   1. 0.16.0 に上げれば建つ            -> 建てて、動かして、版を名乗らせる
#   2. ALLOW_NETWORK_ACCESS は要る      -> 外して建て直し、落ちるのを見る
#   3. zig-depends.mk の四行が正しい    -> zig fetch が何を取ったかを数える
#
# 2 が要るのは、あの行が mk/bsd.pkg.mk でこう効くためである。
#
#	.if !defined(ALLOW_NETWORK_ACCESS)
#	ALL_ENV+=	http_proxy=downloads-forbidden-except-during-fetch
#
# fetch 段の外での download を、壊れた proxy を差し込んで止める。
# lang/zig/application.mk は post-extract で zig fetch を走らせるので、
# 定義が無ければそこで止まるはず。理屈は通るが、測っていなければ書けない。
#
# 説明文が「This can be useful to MAINTAINERs ...」と、メンテナが手元で
# 使うものとして書かれていることも押さえておく。package が恒久的に持つ
# ものではなく、application.mk の TODO (save to distfiles) が片付くまでの
# 借りものである。

PKG=${1:-zakinko/zls}
case $PKG in */*) : ;; *) PKG=zakinko/zls ;; esac

OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
export PATH
unset PKG_PATH

if [ -x "$PREFIX/bin/bmake" ]; then PKGMAKE=$PREFIX/bin/bmake
else PKGMAKE=make; fi
MKARGS=
[ -n "${BINPKG_SITES:-}" ] &&
	MKARGS="DEPENDS_TARGET=bin-install BINPKG_SITES=$BINPKG_SITES"

cd "$TREE/$PKG" || { echo "FAIL: $TREE/$PKG が無い"; exit 1; }
rc=0
echo "--- $PKG ($OS $(uname -r) / $(uname -m)) ---"

# ------------------------------------------------------------------
echo
echo "########## 1. 上げれば建つか ##########"
grep -nE 'DISTNAME|BROKEN' Makefile
pkg_delete -f zls > /dev/null 2>&1 || true
{ $PKGMAKE $MKARGS install 2>&1; echo $? > /tmp/zls-rc; } | tee /tmp/zls-1.log
if [ "$(cat /tmp/zls-rc)" -eq 0 ]; then
	echo 'RESULT 建てる: 通った'
else
	echo 'RESULT 建てる: 落ちた'; tail -40 /tmp/zls-1.log; rc=1
fi

echo "--- 動くか ---"
if [ -x "$PREFIX/bin/zls" ]; then
	"$PREFIX/bin/zls" --version < /dev/null 2>&1 | head -3
	echo "  exit=$?"
else
	echo "!! $PREFIX/bin/zls が無い"; rc=1
fi

echo "--- PLIST どおりか ---"
miss=0
for f in $(pkg_info -qL zls 2>/dev/null); do
	[ -e "$f" ] || { echo "    無い: $f"; miss=$((miss + 1)); }
done
[ $miss -eq 0 ] && echo "  並べたものは全部置かれている" || { echo "FAIL: $miss 個"; rc=1; }

# ------------------------------------------------------------------
echo
echo "########## 2. zig-depends.mk の四行は何を取ったか ##########"
# tracy は build.zig.zon で .lazy = true になっている。print-zig-depends は
# lazy かどうかを見ずに url を全部拾うので、四行のうち一本は使われない
# 可能性がある。実際に取ったかを見る。
for u in known-folders diffz lsp-kit tracy; do
	printf '  %-14s ' "$u"
	grep -c "$u" /tmp/zls-1.log 2>/dev/null | tr -d '\n'
	echo " 回ログに出た"
done

# ------------------------------------------------------------------
echo
echo "########## 3. ALLOW_NETWORK_ACCESS は要るか ##########"
cp Makefile /tmp/zls-Makefile.orig
pkg_delete -f zls > /dev/null 2>&1 || true
$PKGMAKE clean > /dev/null 2>&1
grep -v '^ALLOW_NETWORK_ACCESS' Makefile > Makefile.new && mv Makefile.new Makefile
echo "--- 外した状態 ---"
grep -c ALLOW_NETWORK_ACCESS Makefile

{ $PKGMAKE $MKARGS build 2>&1; echo $? > /tmp/zls-rc; } | tee /tmp/zls-2.log
if [ "$(cat /tmp/zls-rc)" -eq 0 ]; then
	echo 'RESULT 外して建てる: 通った'
	echo '!! 読みが外れている。あの行は要らないことになる。'
	echo '!! send-pr で「要る」と書いてはいけない。'
	rc=1
else
	echo 'RESULT 外して建てる: 落ちた (あの行は要る)'
	echo '--- proxy と zig fetch に触れている行 ---'
	grep -nE 'downloads-forbidden|zig fetch|fetch.*failed|Unable' /tmp/zls-2.log |
		head -10
fi

cp /tmp/zls-Makefile.orig Makefile
$PKGMAKE clean > /dev/null 2>&1

[ $rc -eq 0 ] && echo "=== 通った: $PKG on $OS ===" ||
	echo "=== 見込みと違った: $PKG on $OS ==="
exit $rc
