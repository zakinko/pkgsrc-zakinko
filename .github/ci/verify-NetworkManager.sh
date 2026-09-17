#!/bin/sh
# zakinko/NetworkManager が Linux で建つだけでなく、実際に起動して D-Bus に
# 出てくるところまで見る。
#
#   sh verify-NetworkManager.sh [OPTS]
#
# build-on-bsd.sh が PKGS の名前で引いて呼ぶ。verify-pkg.sh のかわりに
# こちらが使われる。
#
# なぜ要るか
# ----------
# make package が 0 で返ることと、daemon が動くことは別の話である。NM は
# 本体が netlink を直に叩き、udev で機器を数え、D-Bus の system bus に
# 名前を出して初めて仕事をする。package が出来ただけでは、そのどれも
# 踏んでいない。
#
# 段を分けて、どこまで言えるのかを一回で出す。
#
#   1. 建って入る                     package が出来る
#   2. NetworkManager --version       binary が exec できて動的リンクが解ける
#   3. NetworkManager --print-config  設定を読んで自分の状態を組み立てられる
#   4. libnm へリンクした C を走らせる client library が実際に使える
#   5. system bus を立てて daemon を起こし、
#      org.freedesktop.NetworkManager が bus に出るか
#   6. bus 越しに状態を訊く           応答が返る
#
# 4 を別に置くのは、libnm が壊れていても daemon は起きるし、その逆もある
# ため。5 と 6 を分けるのは、名前が出ることと応答することが別だからである。
#
# container の話
# --------------
# NM は rtnetlink を開くので CAP_NET_ADMIN が要る。docker の既定の
# capability 集合には入っていない。workflow 側で --cap-add=NET_ADMIN と
# NET_RAW を渡してある。渡っていなければ 5 で落ちるので、黙って
# 「動かない」で終わらずに理由が出る。
#
# udev は container の中で走っていない。NM は機器を一つも見つけられない
# はずだが、それは起動の失敗ではない。管理対象ゼロで上がることを見る。
# 「実際に回線を張れる」までは、ここでは測らない。測っていないものを
# 測ったことにしない。
set -e

PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
export PATH
unset PKG_PATH

PKG=NetworkManager
DIR=$TREE/zakinko/$PKG
# NetBSD の base の make は pkgsrc の make そのものなので bmake は入らない。
# verify-pkg.sh が同じ分岐を持っている。最初これを写し忘れて
#   /usr/pkg/bin/bmake: not found
# で NetBSD だけ転んだ。
if [ "$(uname -s)" = NetBSD ]; then
	BM=make
else
	BM=$PREFIX/bin/bmake
fi
W=${RUNNER_TEMP:-/tmp}/nm-verify
mkdir -p "$W"

rc=0
step() { printf '\n########## %s ##########\n' "$*"; }
ok()   { printf 'PASS  %s\n' "$*"; }
ng()   { printf 'FAIL  %s\n' "$*"; rc=1; }

# ------------------------------------------------------------------
step "1. 建てて入れる"
cd "$DIR"
pkg_delete -f "$PKG" >/dev/null 2>&1 || true
if $BM DEPENDS_TARGET=package-install install > "$W/build.log" 2>&1; then
	ok "package が出来て入った"
else
	# tail だけでは bmake の停止連鎖しか映らず、本当のエラーが埋もれる。
	# DragonFly で実際にそうなった。devel/libuuid が転んで
	# python313 -> py-flit_core -> ... -> NetworkManager と崩れたのに、
	# 見えたのは "stopped making" の行だけで、compiler が何と言ったのかは
	# 一行も残っていなかった。最初の error とその周辺を先に出す。
	echo "--- 最初の error / fatal ---"
	grep -nE 'error:|fatal error|Error [0-9]+$' "$W/build.log" | head -8 || true
	first=$(grep -nE 'error:|fatal error' "$W/build.log" | head -1 | cut -d: -f1)
	if [ -n "$first" ]; then
		from=$((first - 20)); [ "$from" -lt 1 ] && from=1
		echo "--- $from..$((first + 10)) 行 ---"
		sed -n "${from},$((first + 10))p" "$W/build.log"
	fi
	echo "--- どの package で止まったか ---"
	grep -E 'stopped making' "$W/build.log" | head -8 || true
	echo "--- 末尾 60 行 ---"
	tail -60 "$W/build.log"
	ng "建たない"
	exit 1
fi
pkg_info -e "$PKG" || { ng "pkg_info が $PKG を知らない"; exit 1; }

# PLIST に並べたものが実際に置かれたか
miss=0
for f in $(pkg_info -qL "$PKG" 2>/dev/null); do
	[ -e "$f" ] || { echo "    無い: $f"; miss=$((miss + 1)); }
done
[ "$miss" -eq 0 ] && ok "PLIST の中身が全部ある" || ng "$miss 個が置かれていない"

NMD=$PREFIX/sbin/NetworkManager
[ -x "$NMD" ] || { ng "$NMD が無い"; exit 1; }

# ------------------------------------------------------------------
step "2. binary が exec できるか"
if "$NMD" --version > "$W/version.txt" 2>&1; then
	ok "--version: $(cat "$W/version.txt")"
else
	cat "$W/version.txt"; ng "--version が動かない"
fi
echo "--- 動的リンク ---"
ldd "$NMD" 2>&1 | sed 's/^/    /' | head -20
if ldd "$NMD" 2>&1 | grep -q 'not found'; then
	ldd "$NMD" 2>&1 | grep 'not found' | sed 's/^/    /'
	ng "解けない shared library がある"
else
	ok "shared library は全部解けている"
fi

# ------------------------------------------------------------------
step "3. 設定を読めるか"
if "$NMD" --print-config > "$W/config.txt" 2>&1; then
	ok "--print-config が通った ($(wc -l < "$W/config.txt") 行)"
	head -12 "$W/config.txt" | sed 's/^/    /'
else
	tail -20 "$W/config.txt"; ng "--print-config が通らない"
fi

# ------------------------------------------------------------------
step "4. libnm へリンクした C が動くか"
cat > "$W/t.c" <<'EOF'
#include <NetworkManager.h>
#include <stdio.h>
int main(void) {
	/* bus が要らない口だけを叩く。ここで見たいのは、header が揃っていて
	 * libnm へリンクでき、中の関数が実際に呼べることである。 */
	char *s = nm_utils_ssid_to_utf8((const guint8 *)"pkgsrc", 6);
	printf("libnm ok: ssid=%s header=%d.%d.%d\n",
	       s ? s : "(null)",
	       NM_MAJOR_VERSION, NM_MINOR_VERSION, NM_MICRO_VERSION);
	g_free(s);
	return 0;
}
EOF
CF=$($PREFIX/bin/pkg-config --cflags libnm 2>/dev/null) || CF=
LF=$($PREFIX/bin/pkg-config --libs libnm 2>/dev/null) || LF=
if [ -z "$CF$LF" ]; then
	ng "pkg-config が libnm を知らない"
else
	echo "    cflags: $CF"
	echo "    libs:   $LF"
	if cc -o "$W/t" "$W/t.c" $CF $LF > "$W/cc.log" 2>&1; then
		if out=$(LD_LIBRARY_PATH=$PREFIX/lib "$W/t" 2>&1); then
			ok "libnm へリンクして実行できた: $out"
		else
			echo "$out" | sed 's/^/    /'; ng "リンクはできたが走らない"
		fi
	else
		tail -20 "$W/cc.log" | sed 's/^/    /'; ng "libnm へリンクできない"
	fi
fi

# ------------------------------------------------------------------
step "5. system bus を立てて daemon を起こす"
echo "--- capability ---"
if command -v capsh >/dev/null 2>&1; then capsh --print | head -3 | sed 's/^/    /'; fi
grep -i '^CapEff' /proc/self/status 2>/dev/null | sed 's/^/    /' || true

mkdir -p /var/run/dbus "$PREFIX/etc/NetworkManager/system-connections"
DBUSD=$PREFIX/bin/dbus-daemon
if [ ! -x "$DBUSD" ]; then
	ng "$DBUSD が無い"
else
	"$DBUSD" --system --fork --print-pid > "$W/dbus.pid" 2>"$W/dbus.log" || {
		cat "$W/dbus.log" | sed 's/^/    /'; ng "system bus が立たない"; }
	if [ -s "$W/dbus.pid" ]; then
		ok "system bus が立った (pid $(cat "$W/dbus.pid"))"

		"$NMD" --no-daemon > "$W/nm.log" 2>&1 &
		NMPID=$!
		echo "    NetworkManager pid=$NMPID"
		# bus に名前が出るまで待つ。上限を切る。
		i=0; seen=no
		while [ $i -lt 30 ]; do
			if $PREFIX/bin/dbus-send --system --print-reply --dest=org.freedesktop.DBus \
			   /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>/dev/null |
			   grep -q 'org.freedesktop.NetworkManager'; then
				seen=yes; break
			fi
			kill -0 $NMPID 2>/dev/null || break
			i=$((i + 1)); sleep 1
		done

		if [ "$seen" = yes ]; then
			ok "org.freedesktop.NetworkManager が bus に出た ($i 秒)"

			# --------------------------------------------------
			step "6. bus 越しに状態を訊く"
			if $PREFIX/bin/dbus-send --system --print-reply \
			   --dest=org.freedesktop.NetworkManager \
			   /org/freedesktop/NetworkManager \
			   org.freedesktop.DBus.Properties.Get \
			   string:org.freedesktop.NetworkManager string:State \
			   > "$W/state.txt" 2>&1; then
				ok "State に応答した: $(tr -d '\n' < "$W/state.txt" | sed 's/  */ /g')"
			else
				cat "$W/state.txt" | sed 's/^/    /'; ng "State を訊けない"
			fi
			$PREFIX/bin/dbus-send --system --print-reply \
			   --dest=org.freedesktop.NetworkManager \
			   /org/freedesktop/NetworkManager \
			   org.freedesktop.DBus.Properties.Get \
			   string:org.freedesktop.NetworkManager string:Version 2>&1 |
			   sed 's/^/    /' || true
		else
			ng "bus に名前が出ない"
		fi

		echo "--- daemon の言い分 ---"
		sed 's/^/    /' "$W/nm.log" | head -40
		kill $NMPID 2>/dev/null || true
		wait $NMPID 2>/dev/null || true
		kill "$(cat "$W/dbus.pid")" 2>/dev/null || true
	fi
fi

# ------------------------------------------------------------------
step "後始末"
$BM deinstall > /dev/null 2>&1 || pkg_delete "$PKG" > /dev/null 2>&1 || ng "外せない"
pkg_info -e "$PKG" >/dev/null 2>&1 && ng "外したのに残っている" || ok "外せた"

echo
if [ $rc -eq 0 ]; then
	echo "=== 通った: $PKG on Linux (起動と D-Bus まで) ==="
else
	echo "=== 通らなかった段がある ==="
fi
exit $rc
