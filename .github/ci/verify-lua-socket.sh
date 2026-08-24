#!/bin/sh
# net/lua-socket の当て物が illumos で効いているかを実機で見る。
#
#   sh verify-lua-socket.sh <カテゴリ>/<パッケージ>
#
# build-on-bsd.sh が TREE_PKGS から名前で引いて呼ぶ。当て物ではない
# 上流そのままの package を見るので、zakinko/ には何も置いていない。
#
# 何を見ているか
# --------------
# GitHub の NetBSD/pkgsrc PR #173 は「SunOS に sun_len は無い」として
# net/lua-socket の Makefile から
#
#	CFLAGS.SunOS=	-DUNIX_HAS_SUN_LEN
#
# を落とすもの。pkgsrc は 2026-02-26 に別の直し方を採った (PR 60039,
# sborrill)。patch-src_unixdgram.c と patch-src_unixstream.c で sun_len
# への代入を消し、長さは SUN_LEN() マクロから取る。CFLAGS.SunOS の行は
# 今も残っているので、PR が消せと言っている行はそのままである。
#
# illumos の <sys/un.h> は struct sockaddr_un を sun_family と sun_path
# だけで定義していて、そこに
#
#	NOTE: If we ever go to BSD-style sun_len + sun_family, this macro
#	needs to change.
#
# と書いてある。sun_len は無い。一方 SUN_LEN() は同じヘッダが持っていて、
# _XOPEN_SOURCE も _POSIX_C_SOURCE も定義しなければ見える。luasocket は
# どちらも定義しない。だから当て物があれば -DUNIX_HAS_SUN_LEN が残って
# いても通るはず、というのがこちらの読み。
#
# 見るのは三つ。
#
#   1. 当て物ありで建てる            -> 通るはず
#   2. 建った module で unix socket を通す
#   3. 当て物二本を外して建て直す    -> sun_len で落ちるはず
#
# 3 を見ないと、1 が「当て物が効いている」のか「元から問題が無かった」
# のかが分からない。転けるのを見てから、直っているのを見る。
#
# 2 が要るのは、当て物が bind/connect/sendto に渡す長さを
# sizeof(sun_family)+sizeof(sun_len)+len+1 から SUN_LEN() へ変えている
# ため。型が通ることと、その長さで kernel が受けることは別の話である。
# stream の bind/connect と dgram の bind/sendto/connect で、当て物が
# 触った五箇所を全部通る。

PKG=${1:-net/lua-socket}

OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}

PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
export PATH
unset PKG_PATH

if [ "$OS" = NetBSD ]; then
	PKGMAKE=make
	MKARGS=
else
	PKGMAKE=$PREFIX/bin/bmake
	MKARGS="DEPENDS_TARGET=package-install"
fi

DIR=$TREE/$PKG
cd "$DIR" || { echo "FAIL: $DIR が無い"; exit 1; }

rc=0

echo "--- $PKG ($OS $(uname -r) / $(uname -m)) ---"

# ------------------------------------------------------------------
echo
echo "########## 0. この箱の sockaddr_un ##########"
if [ -f /usr/include/sys/un.h ]; then
	sed -n '/struct[[:space:]]*sockaddr_un/,/};/p' /usr/include/sys/un.h
	echo '--- SUN_LEN ---'
	grep -n 'SUN_LEN' /usr/include/sys/un.h || echo '(<sys/un.h> に SUN_LEN が無い)'
else
	echo '(/usr/include/sys/un.h が無い)'
fi
echo '--- pkgsrc が SunOS へ渡しているもの ---'
grep -n 'SunOS' Makefile

# ------------------------------------------------------------------
echo
echo "########## 1. 当て物ありで建てる ##########"
ls patches
pkg_delete -f lua-socket > /dev/null 2>&1 || true
if $PKGMAKE $MKARGS install > /tmp/ls-patched.log 2>&1; then
	echo 'RESULT 当て物あり: 通った'
else
	echo 'RESULT 当て物あり: 落ちた'
	grep -n 'sun_len' /tmp/ls-patched.log | head -20
	tail -40 /tmp/ls-patched.log
	rc=1
fi

# ------------------------------------------------------------------
echo
echo "########## 2. unix socket を実際に通す ##########"
cat > /tmp/unixtest.lua <<'EOF'
local unix = require"socket.unix"

local spath = "/tmp/ls-stream.sock"
local dpath = "/tmp/ls-dgram.sock"
local cpath = "/tmp/ls-dgram-cli.sock"
for _, p in ipairs{spath, dpath, cpath} do os.remove(p) end

-- stream: bind -> listen -> connect -> accept -> send -> receive
local srv = assert(unix.stream())
assert(srv:bind(spath))
assert(srv:listen(1))
local cli = assert(unix.stream())
assert(cli:connect(spath))
local con = assert(srv:accept())
assert(cli:send("stream ok\n"))
local line = assert(con:receive())
print("stream:", line)
assert(line == "stream ok", "stream の中身が違う")
con:close(); cli:close(); srv:close()

-- dgram: bind -> sendto -> receivefrom
local ds = assert(unix.dgram())
assert(ds:bind(dpath))
local dc = assert(unix.dgram())
assert(dc:bind(cpath))
assert(dc:sendto("dgram ok", dpath))
local data = assert(ds:receivefrom())
print("dgram:", data)
assert(data == "dgram ok", "dgram の中身が違う")
dc:close()

-- dgram の connect も当て物が触った五箇所目なので通す
local dc2 = assert(unix.dgram())
assert(dc2:connect(dpath))
assert(dc2:send("dgram connected"))
local data2 = assert(ds:receive())
print("dgram connect:", data2)
assert(data2 == "dgram connected", "dgram connect の中身が違う")
dc2:close(); ds:close()

for _, p in ipairs{spath, dpath, cpath} do os.remove(p) end
print("RESULT 実行: 通った")
EOF

# lua の名前は版で変わる。素の lua が無ければ lua5.4 / lua54 を探す。
LUA=
for l in "$PREFIX/bin/lua" "$PREFIX/bin/lua5.4" "$PREFIX/bin/lua54" \
         "$PREFIX/bin/lua5.3" "$PREFIX/bin/lua53"; do
	[ -x "$l" ] && { LUA=$l; break; }
done
[ -n "$LUA" ] || LUA=$(ls "$PREFIX"/bin/lua* 2>/dev/null | head -1)
if [ -z "$LUA" ]; then
	echo "!! lua が $PREFIX/bin に無い"
	ls "$PREFIX/bin" | head -30
	rc=1
else
	echo "--- $LUA で回す ---"
	"$LUA" /tmp/unixtest.lua || { echo 'RESULT 実行: 落ちた'; rc=1; }
fi

# ------------------------------------------------------------------
echo
echo "########## 3. 当て物を外して、転けることを見る ##########"
# ここは箱によって答えが割れる。
#
# Makefile が -DUNIX_HAS_SUN_LEN を渡すのは Darwin と FreeBSD と NetBSD と
# SunOS だけである。Linux では渡らないので、当て物のある枝に入らない。
# つまり Linux で「当て物なしでも組める」のは正しい結果であって、失敗では
# ない。最初それを rc=1 にしていて、Debian の job を落としていた。
case $OS in
Darwin|FreeBSD|NetBSD|SunOS)	EXPECT_FAIL=yes ;;
*)				EXPECT_FAIL=no ;;
esac
echo "--- この箱で -DUNIX_HAS_SUN_LEN は渡るか: $EXPECT_FAIL ---"

cp distinfo /tmp/distinfo.orig
cp patches/patch-src_unixdgram.c /tmp/ 2>/dev/null || true
cp patches/patch-src_unixstream.c /tmp/ 2>/dev/null || true

$PKGMAKE clean > /dev/null 2>&1
pkg_delete -f lua-socket > /dev/null 2>&1 || true
rm -f patches/patch-src_unixdgram.c patches/patch-src_unixstream.c
sed -e '/patch-src_unixdgram.c/d' -e '/patch-src_unixstream.c/d' \
    distinfo > distinfo.new && mv distinfo.new distinfo
ls patches

if $PKGMAKE $MKARGS build > /tmp/ls-plain.log 2>&1; then
	if [ "$EXPECT_FAIL" = yes ]; then
		echo 'RESULT 当て物なし: 通った'
		echo '!! 読みが外れている。この箱は -DUNIX_HAS_SUN_LEN を渡すので、'
		echo '!! 当て物が無ければ sun_len で落ちるはずだった。'
		rc=1
	else
		echo "RESULT 当て物なし: 通った ($OS は -DUNIX_HAS_SUN_LEN を渡さないので当然)"
	fi
else
	if [ "$EXPECT_FAIL" = yes ]; then
		echo 'RESULT 当て物なし: 落ちた (PR #173 が言うとおり)'
	else
		echo "RESULT 当て物なし: 落ちた ($OS では当て物と関係なく落ちている)"
		tail -30 /tmp/ls-plain.log
		rc=1
	fi
fi
echo '--- sun_len に触れている行 ---'
grep -n 'sun_len' /tmp/ls-plain.log | head -20
echo '--- 最後の 30 行 ---'
tail -30 /tmp/ls-plain.log

# 戻す。あとの job が同じツリーを使うので、壊したままにしない。
cp /tmp/distinfo.orig distinfo
cp /tmp/patch-src_unixdgram.c patches/ 2>/dev/null || true
cp /tmp/patch-src_unixstream.c patches/ 2>/dev/null || true
$PKGMAKE clean > /dev/null 2>&1

[ $rc -eq 0 ] && echo "=== 通った: $PKG on $OS ===" ||
	echo "=== 見込みと違った: $PKG on $OS ==="
exit $rc
