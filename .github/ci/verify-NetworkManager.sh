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
step "0. 道具の素性"
# OpenBSD 7.9 で textproc/libxml2 の configure が
#
#	checking pkg-config is at least version 0.9.0... Segmentation fault (core dumped)
#	configure: error: pkg-config not found
#
# で止まった。落ちているのが host の pkg-config なのか、pkgsrc が建てた
# pkgconf なのか、tools の wrapper なのかで直す先が変わる。建て始める前に
# 素性を採る。ここは転んでも先へ進む。どの箱でも一度は見ておきたい。
for t in pkg-config pkgconf; do
	w=$(command -v "$t" 2>/dev/null) || w=""
	if [ -z "$w" ]; then
		printf '  %-12s PATH に無い\n' "$t"
		continue
	fi
	printf '  %-12s %s\n' "$t" "$w"
	printf '    file:    '; file "$w" 2>/dev/null | cut -c1-120 || echo "(file が無い)"
	printf '    version: '
	if v=$("$w" --version 2>&1); then
		echo "$v"
	else
		st=$?
		echo "落ちた (exit=$st)"
		[ "$st" -gt 128 ] && echo "    signal $((st - 128)) で死んだ"
	fi
done
printf '  %-12s %s\n' "pkg_info" "$(pkg_info -e pkgconf 2>/dev/null || echo '(pkgconf は入っていない)')"

# OpenBSD 7.9 で落ちたのは --version ではなく、configure が撃つ別の呼び方で
# ある可能性がある。PKG_PROG_PKG_CONFIG の m4 は
#
#	$PKG_CONFIG --atleast-pkgconfig-version 0.9.0
#
# を撃ち、そこで Segmentation fault (core dumped) が出て
#	configure: error: pkg-config not found
# になった。--version は通っているので、binary そのものではなく呼び方か
# 環境の側を疑う。configure と同じ形で撃ってみる。
w=$(command -v pkg-config 2>/dev/null) || w=""
if [ -n "$w" ]; then
	echo "  configure と同じ呼び方:"
	for a in "--atleast-pkgconfig-version 0.9.0" "--exists glib-2.0" "--list-all"; do
		printf '    %-34s ' "$a"
		if out=$("$w" $a 2>&1 | head -1); then
			echo "通る ${out:+($out)}"
		else
			st=$?
			if [ "$st" -gt 128 ]; then
				echo "signal $((st - 128)) で死んだ"
			else
				echo "exit=$st ${out:+: $out}"
			fi
		fi
	done
	echo "  環境:"
	printf '    PKG_CONFIG_LIBDIR=%s\n' "${PKG_CONFIG_LIBDIR:-(空)}"
	printf '    PKG_CONFIG_PATH=%s\n' "${PKG_CONFIG_PATH:-(空)}"
	printf '    ulimit -s=%s  -d=%s\n' "$(ulimit -s 2>/dev/null)" "$(ulimit -d 2>/dev/null)"
fi

# ------------------------------------------------------------------
step "0.5 pkglint"
# 手元では掛けられない。pkglint は完全な木を要り、mk だけ symlink した偽の木は
#   FATAL: ../../editors/emacs/modules.mk: Cannot be read.
# で止まる。木が在るのはここなので、ここで掛ける。
#
# 落ちても先へは進む。pkglint の指摘は「送る前に直す」ためのもので、建つか
# どうかとは別の検査である。数だけでなく中身を出す。
if command -v pkglint > /dev/null 2>&1; then
	for p in libndp NetworkManager; do
		d=$TREE/zakinko/$p
		[ -d "$d" ] || { echo "  $p: 木に無い"; continue; }
		echo "--- $p ---"
		( cd "$d" && pkglint . 2>&1 | tail -20 ) || true
	done
else
	echo "  pkglint が入っていない (pkgtools/pkglint)"
fi

# ------------------------------------------------------------------
step "0.7 security/polkit を FreeBSD 系でも通す"
# polkit-127 の polkitagenthelper-pam.c は SO_PEERPIDFD の区画で errno を
# ENODATA と比べる。polkit は SO_PEERPIDFD を持たない系でも自前で 77 と
# define するので区画が常に compile され、ENODATA を持たない FreeBSD 系で
#
#   polkitagenthelper-pam.c:156:48: error: use of undeclared identifier 'ENODATA'
#
# になる。NetBSD には ENODATA が在るので落ちない。pkgsrc の既存の当て物は
# SO_PEERCRED の半分だけで、FreeBSD 側は FreeBSD ports の sysutils/polkit が
# 持っている。両方を素の 127 に当てて diff を取り直した合成版がここに在る。
#
# 最初これを tree-patch でやって Linux を壊した。あちらは bootstrap より前に
# 走るので、当時は数え方が合わず Ignoring patch file ... invalid checksum で
# patch 段ごと転んだ。「自分で数えるな、makepatchsum に数えさせろ」と書いた
# のはそのときで、**半分だけ正しかった。**
#
# 数え方そのものは合う。$NetBSD$ の行を落とした SHA1 が pkgsrc の値である
# ことは、NetworkManager の当て物二十四本で確かめてあり、CI の distinfo の
# 段も通っている。当時外したのは、その一行を落としていなかった側だと思う。
#
# 一方で makepatchsum は distinfo 全体を書き直すので、CI では
#
#   SHA1 (A) = SHA1 (B) = <B の hash>
#
# と二件が一行に繋がることがあった。行数も行末も合うので検査をすり抜け、
# pkgsrc は invalid checksum として当て物を黙って飛ばす。なぜ繋がるかは
# 分かっていない。techne では同じ操作が正しく動く。
#
# **書き換えるのは一行だけで済む。**全体を書き直さなければ繋がる余地が無い。
pkdir=$TREE/security/polkit
pksrc=$(dirname "$0")/tree-patches/patch-src_polkitagent_polkitagenthelper-pam.c
pkdst=$pkdir/patches/patch-src_polkitagent_polkitagenthelper-pam.c
if [ -f "$pkdst" ] && [ -f "$pksrc" ]; then
	if grep -q 'SO_PEERPIDFD' "$pkdst"; then
		echo "  既に SO_PEERPIDFD を見ている。そのまま"
	else
		# distinfo だけでなく当て物そのものも控える。戻すときに git は
		# 使えない — CI の木は tarball で展開したもので、git 管理下に無い。
		# distinfo だけ戻すと、差し替えた当て物が checksum 不一致になって
		# 結局飛ぶ。壊れた状態が別の顔で残るだけになる。
		# distinfo だけでなく当て物そのものも控える。戻すときに git は
		# 使えない — CI の木は tarball で展開したもので、git 管理下に無い。
		cp "$pkdir/distinfo" "$W/polkit-distinfo.orig"
		cp "$pkdst" "$W/polkit-patch.orig"
		cp "$pksrc" "$pkdst"

		# makepatchsum は呼ばない。CI では distinfo 全体を書き直した結果
		#
		#   SHA1 (A) = SHA1 (B) = <B の hash>
		#
		# という形で二件が一行に繋がることがあった。行数も行末も合うので
		# 検査をすり抜け、pkgsrc は invalid checksum として当て物を黙って
		# 飛ばす。polkit が素で建ち、当て物が直すはずの error が出る。
		#
		# 書き換えるのは一行だけで済む。数え方は pkgsrc と同じ — $NetBSD$
		# の行を落とした SHA1 で、NetBSD の実機で makepatchsum と同じ値
		# (b216799b…) が出ることを確かめてある。全体を書き直さなければ、
		# 行が繋がる余地が無い。
		h=$(sed -e '/\$NetBSD.*\$/d' "$pkdst" | digest sha1 2>/dev/null |
		    awk '{print $NF}')
		case "$h" in
		????????????????????????????????????????)
			awk -v n="$(basename "$pkdst")" -v h="$h" '
				$0 ~ "^SHA1 \\(" n "\\) = " { print "SHA1 (" n ") = " h; next }
				{ print }
			' "$pkdir/distinfo" > "$pkdir/distinfo.new" &&
				mv "$pkdir/distinfo.new" "$pkdir/distinfo"
			;;
		*)
			echo "  ★ SHA1 が 40 桁で出ない (digest: $(command -v digest || echo 'PATH に無い'))"
			cp "$W/polkit-distinfo.orig" "$pkdir/distinfo"
			cp "$W/polkit-patch.orig" "$pkdst"
			h=
			;;
		esac

		if [ -n "$h" ]; then
			# 書けたかは跡で測る。行数、当て物の数、SHA1 の出現数、値の形。
			# 出現数まで見るのは、二件が一行に繋がっても行数は合うため。
			want=$(ls "$pkdir/patches" | grep -c '^patch-' || true)
			got=$(grep -c '^SHA1 (patch-' "$pkdir/distinfo" || true)
			ent=$(grep -o 'SHA1 (patch-' "$pkdir/distinfo" | wc -l | tr -d ' ')
			bad=$(grep '^SHA1 (patch-' "$pkdir/distinfo" |
			      grep -cv '= [0-9a-f][0-9a-f]*$' || true)
			echo "  distinfo: $(wc -lc < "$pkdir/distinfo" | tr -s ' ') (行 byte)"
			if [ "$want" = "$got" ] && [ "$got" = "$ent" ] && [ "$bad" = 0 ]; then
				echo "  差し替えて一行だけ数え直した ($got 本)"
				grep 'polkitagenthelper-pam' "$pkdir/distinfo" | cat -v | sed 's/^/    /'
			else
				echo "  ★ distinfo が壊れた (当て物 $want / 行 $got / 出現 $ent / 変な行 $bad)"
				sed -n '1,12p' "$pkdir/distinfo" | cat -v | sed 's/^/    /'
				cp "$W/polkit-distinfo.orig" "$pkdir/distinfo"
				cp "$W/polkit-patch.orig" "$pkdst"
				echo "    元に戻した。polkit は木のままで建てる"
			fi
		fi
	fi
else
	echo "  security/polkit が見当たらない。そのまま"
fi

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
