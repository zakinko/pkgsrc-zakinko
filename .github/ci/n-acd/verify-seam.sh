#!/bin/sh
# n-acd の移植の継ぎ目を、当て物から取り出してその場で建てて測る。
#
# NetworkManager 本体は BSD では継ぎ目より手前で止まるので、本体の build を
# 待っていると継ぎ目は一生測られない。測る対象は package が配る当て物その
# もの — patch の中の + を剥いで file に戻す — なので、当て物を直せばここが
# 測る物も一緒に変わる。写しを置くと、本物を直した日に緑のまま意味を失う。
#
# 建つことと動くことは別なので、建てるだけで終わらせない。timer は実際に
# 焼かせて時刻を測り、framing は kernel が返すのと同じ形の buffer を作って
# 一 byte まで突き合わせる。配布物が置いてあれば、そのあと n-acd を丸ごと
# 建てて実際に ARP を撃つ。

# 自分の位置から辿る。pwd に頼ると、呼ぶ側の cwd で意味が変わる。
# run-in-qemu.sh はゲストの /tmp へ置いて root の home から呼ぶので、
# pwd では NetworkManager/patches に届かなかった。
CI=$(cd "$(dirname "$0")" && pwd)
TOP=$(cd "$CI/../../.." && pwd)
P="$TOP/NetworkManager/patches"
W="$TOP/nacdseam"

if [ ! -d "$P" ]; then
	echo "★ 当て物が見付からない ($P)"
	exit 1
fi
# 消せなければ止める。mkdir -p は既に在れば成功するので、前の回の残骸が
# 消えていないことに気付かないまま進み、古い物を測ってしまう。
rm -rf "$W" || { echo "★ $W を消せない"; exit 1; }
mkdir -p "$W" || exit 1

# 当て物から中身を取り出す。@@ の次の行から、行頭の + を一つ剥ぐ。
unpatch() {
	awk '/^@@ /{go=1; next} go{sub(/^\+/,""); print}' "$1" > "$2"
	if [ ! -s "$2" ]; then
		echo "★ $1 から中身が取り出せない"
		exit 1
	fi
}

unpatch "$P/patch-src_n-acd_src_n-acd-os.h"     "$W/n-acd-os.h"
unpatch "$P/patch-src_n-acd_src_n-acd-os-bsd.c" "$W/n-acd-os-bsd.c"
cp "$CI/t-timer.c" "$CI/t-framing.c" "$W/"

echo "=== 何で建てるか"
uname -a
cc --version 2>/dev/null | head -1 || cc -v 2>&1 | head -1

CFLAGS="-std=c11 -Wall -Wextra -I$W"

echo
echo "=== 継ぎ目を建てる (警告が一つでも出たら落とす)"
cd "$W" || exit 1
if ! cc $CFLAGS -c n-acd-os-bsd.c -o seam.o 2> cc.log; then
	echo "★ 建たない"; cat cc.log; exit 1
fi
if [ -s cc.log ]; then
	echo "★ 警告が出た。NetBSD では零だったので、この OS で何かが違う"
	cat cc.log; exit 1
fi
echo "  建った。警告なし"

echo
echo "=== 継ぎ目が出す名前"
nm -g seam.o 2>/dev/null | grep ' T n_acd_os' | awk '{print "  " $3}'

echo
echo "=== timer を測る (焼ける時刻を実際に見る)"
cc $CFLAGS -o t-timer t-timer.c seam.o || exit 1
./t-timer || exit 1

echo
echo "=== framing を測る (本物を取り込んだ test)"
cc $CFLAGS -o t-framing t-framing.c || exit 1
./t-framing || exit 1

# ---- ここから先は配布物が置いてあるときだけ ----
#
# 継ぎ目が建つことと、n-acd が実際に ARP を撃って答えを読めることは別なので、
# 撃てる場所では撃つ。vmactions の VM は root で走り、本物の interface を
# 持っているので撃てる。default route の先には必ず誰かが居るので、そこを
# 探らせて N_ACD_EVENT_USED が返るかを見る。返るということは送信・filter・
# framing・timer・state machine が一本に繋がっているということで、どれか
# 一つ切れていれば返らない。
#
# 撃つのは ARP request で、spa は 0、誰の address も主張しない。DHCP client
# が起動のたびにやっているのと同じものなので、segment に影響しない。

DIST=${DIST:-$TOP/NetworkManager.tar.bz2}

# 置いてなければ取りにいく。runner で cache する経路では既に在るので通らない。
# qemu のゲストのように自分で取るしかない場所のためのもの。
if [ ! -f "$DIST" ] && [ -n "${DIST_URL:-}" ]; then
	echo
	echo "=== 配布物を取る"
	if command -v ftp > /dev/null 2>&1; then
		ftp -o "$DIST" "$DIST_URL" || rm -f "$DIST"
	elif command -v curl > /dev/null 2>&1; then
		curl -sSfL -o "$DIST" "$DIST_URL" || rm -f "$DIST"
	elif command -v fetch > /dev/null 2>&1; then
		fetch -o "$DIST" "$DIST_URL" || rm -f "$DIST"
	fi
fi

if [ ! -f "$DIST" ]; then
	echo
	echo "=== 実機の ARP は測らない (配布物が無い)"
	echo "=== ここまで全部通った"
	exit 0
fi

echo
echo "=== 配布物を展開して n-acd を丸ごと建てる"
cd "$W" || exit 1
rm -rf full; mkdir full || exit 1
( cd full && bzcat "$DIST" | tar xf - ) || exit 1
NM=`echo "$W"/full/NetworkManager-*`
[ -d "$NM/src/n-acd" ] || { echo "★ n-acd が見付からない ($NM)"; exit 1; }

# 当て物は -i で渡す。`< "$p" < /dev/null` と書くと、後の redirect が勝つ
# 側の shell では patch が /dev/null を読み、当たっていないのに rc=0 で
# 返ってくる。zsh は MULTIOS で両方渡すので手元では再現しない。
#
# その rc も信じない。NetBSD の patch は中身を見付けられなくても 0 を返し、
# "I can't seem to find a patch in there anywhere." と言うだけだった。
# 当たったかどうかは、当たった跡で測る。
echo "=== 当て物を当てる (package が配る物そのもの)"
cd "$NM" || exit 1
n=0
for p in "$P"/patch-*; do
	patch -p0 -s -f -i "$p" < /dev/null
	n=`expr $n + 1`
done
if [ ! -f src/n-acd/src/n-acd-os-bsd.c ]; then
	echo "★ 当て物が当たっていない (n-acd-os-bsd.c が出来ていない)"
	exit 1
fi
if grep -q 'linux/if_packet.h' src/n-acd/src/n-acd.c; then
	echo "★ 当て物が当たっていない (n-acd.c がまだ linux/if_packet.h を読む)"
	exit 1
fi
if ls src/n-acd/src/*.rej src/*.rej > /dev/null 2>&1; then
	echo "★ .rej が残っている"; ls src/n-acd/src/*.rej src/*.rej 2>/dev/null; exit 1
fi
echo "  $n 本当てて、跡を確かめた"

echo "=== n-acd を丸ごと建てる"
S="$NM/src"
INC="-I$S/n-acd/src -I$S/c-list/src -I$S/c-rbtree/src -I$S/c-siphash/src -I$S/c-stdaux/src"
CF="-std=c11 -Wall -Wextra -Wno-unused-parameter $INC"
OBJ=""
for f in "$S"/n-acd/src/n-acd.c "$S"/n-acd/src/n-acd-probe.c \
         "$S"/n-acd/src/util/timer.c "$S"/n-acd/src/n-acd-bpf-fallback.c \
         "$S"/n-acd/src/n-acd-os-bsd.c "$S"/c-rbtree/src/c-rbtree.c \
         "$S"/c-siphash/src/c-siphash.c; do
	b=`basename "$f" .c`
	if ! cc $CF -c "$f" -o "$W/o_$b.o" 2> "$W/cc_$b.log"; then
		echo "★ $b が建たない"; head -25 "$W/cc_$b.log"; exit 1
	fi
	if [ -s "$W/cc_$b.log" ]; then
		echo "★ $b で警告が出た"; cat "$W/cc_$b.log"; exit 1
	fi
	OBJ="$OBJ $W/o_$b.o"
done
echo "  七本とも警告なしで建った"

cc $CF -o "$W/t-probe" "$CI/t-probe.c" $OBJ || exit 1

# n-dhcp4 も同じ木に居る。n-acd より後に移したもので、Linux が出てくる場所は
# socket と poller と timer の三つに固まっていた。ここでは建つかだけを見る。
# 線に出すところまでは NetBSD の実機で別に測ってある (tap を立てて捕まえた)。
echo
echo "=== n-dhcp4 を丸ごと建てる"
DS="$NM/src/n-dhcp4/src"
DF="-std=c11 -Wall -Wextra -Wno-unused-parameter -I$DS -I$S/c-list/src -I$S/c-siphash/src -I$S/c-stdaux/src"
dfail=0
for f in "$DS"/n-dhcp4-socket.c "$DS"/n-dhcp4-socket-bsd.c "$DS"/util/packet.c \
         "$DS"/util/packet-bsd.c "$DS"/util/socket-bsd.c "$DS"/n-dhcp4-client.c \
         "$DS"/n-dhcp4-c-connection.c "$DS"/n-dhcp4-c-probe.c "$DS"/n-dhcp4-c-lease.c \
         "$DS"/n-dhcp4-incoming.c "$DS"/n-dhcp4-outgoing.c; do
	b=`basename "$f" .c`
	if ! cc $DF -c "$f" -o "$W/dh_$b.o" 2> "$W/dh_$b.log"; then
		echo "★ $b が建たない"; head -25 "$W/dh_$b.log"; dfail=1
	elif [ -s "$W/dh_$b.log" ]; then
		echo "★ $b で警告が出た"; cat "$W/dh_$b.log"; dfail=1
	fi
done
[ $dfail = 0 ] || exit 1
echo "  十一本とも警告なしで建った"

# c-stdaux は BSD では unix module を読まない。c-stdaux.h が
# c-stdaux-unix.h を include する条件が C_OS_LINUX と C_OS_MACOS の二つだけ
# だからで、c_close() も c_closedir() も C_MODULE_UNIX も現れない。上流へ
# 出す当て物をここで当て、当てる前は建たず当てた後は建つことを測る。
#
# 当たる先は NetworkManager 同梱の写しだが、触る三つの file は上流 main と
# 一 byte も違わない。当てる前に建ってしまったら前提のほうが変わっているので、
# そこで止める。
echo
echo "=== c-stdaux の BSD 対応 (上流へ出す当て物)"
CS="$S/c-stdaux"
CSP="$CI/../c-stdaux"
if cc -I"$CS/src" -o "$W/cs-probe" "$CSP/probe.c" 2> "$W/cs0.log"; then
	echo "★ 当てる前から probe が建った。前提が変わっている"
	exit 1
fi
echo "  当てる前: 建たない — `sed -n 's/.*error: *//p' "$W/cs0.log" | head -1`"
( cd "$CS" && patch -p0 -s -f -F0 -i "$CSP/c-stdaux-bsd.diff" < /dev/null )
if ! grep -q C_OS_BSD "$CS/src/c-stdaux.h"; then
	echo "★ 当て物が当たっていない"; exit 1
fi
if ls "$CS"/src/*.rej > /dev/null 2>&1; then
	echo "★ .rej が残っている"; ls "$CS"/src/*.rej; exit 1
fi
if ! cc -I"$CS/src" -o "$W/cs-probe" "$CSP/probe.c" 2> "$W/cs1.log"; then
	echo "★ 当てた後も建たない"; cat "$W/cs1.log"; exit 1
fi
"$W/cs-probe" || { echo "★ probe が落ちた"; exit 1; }
for t in test-api test-basic; do
	if ! cc -I"$CS/src" -o "$W/cs-$t" "$CS/src/$t.c" 2> "$W/cs-$t.log"; then
		echo "★ $t が建たない"; head -20 "$W/cs-$t.log"; exit 1
	fi
	"$W/cs-$t" || { echo "★ $t が落ちた"; exit 1; }
done
echo "  当てた後: C_OS_BSD と C_MODULE_UNIX が立ち、test-api と test-basic が通った"

# filter の offset を移す変更は、間違えても静かに壊れる。行き過ぎれば何も
# 来ず、足りなければ何でも来る。root が要るので BPF device では測れないが、
# libpcap の bpf_filter() は kernel と同じ interpreter なので、当て物が置く
# 実物の filter と上流の Linux 版を同じ packet に通して比べられる。
#
# 取り込むのは実物である。写しを置くと、本物を直した日に緑のまま意味を失う。
echo
echo "=== packet の送受信を測る"
if cc $DF -I"$DS"/util -o "$W/t-packet" "$CI/../n-dhcp4/t-packet.c" \
        "$DS"/util/packet.c 2> "$W/tp.log"; then
	"$W/t-packet"
	r=$?
	# 77 は Ethernet の interface が無い場合。測れないのは落ちたのとは違う。
	[ $r = 0 ] || [ $r = 77 ] || exit $r
else
	echo "  建たない:"; head -10 "$W/tp.log"; exit 1
fi

echo
echo "=== filter を上流の Linux 版と突き合わせる"
if cc $DF -I"$DS"/util -o "$W/t-filter" "$CI/../n-dhcp4/t-filter.c" \
        "$DS"/n-dhcp4-incoming.c "$DS"/util/socket-bsd.c \
        "$DS"/util/packet.c "$DS"/util/packet-bsd.c -lpcap 2> "$W/tf.log"; then
	"$W/t-filter" || exit 1
else
	# libpcap が無い BSD があれば、そこは測らない。落とすほどではない。
	echo "  建たないので測らない:"
	head -6 "$W/tf.log"
fi

GW=`netstat -rn -f inet 2>/dev/null | awk '$1=="default"{print $2; exit}'`
if [ -z "$GW" ]; then
	echo "=== default route が無いので撃たない"
	echo "=== ここまで全部通った"
	exit 0
fi

# 空いている address は決め打ちできない。gateway と同じ /24 の末尾寄りを
# 使う。誰か居れば USED が返って test は「期待と違う」と言うが、それは
# 間違いではなく、その箱の segment が混んでいるという事実である。
FREE=`echo "$GW" | awk -F. '{printf "%s.%s.%s.231", $1, $2, $3}'`

echo
echo "=== 実機で ARP を撃つ (gateway $GW を USED、$FREE を READY と期待)"
"$W/t-probe" "$GW" "$FREE"
r=$?
# 77 は /dev/bpf を開けなかった側。権限が無いのは「測れなかった」であって
# 「落ちた」ではない。CI の VM は root なので出ないが、手で走らせたときに
# 赤にしても意味が無い。
if [ $r = 77 ]; then
	echo "  root でないので撃てなかった (継ぎ目の手前までは通っている)"
	echo
	echo "=== ここまで全部通った"
	exit 0
fi
[ $r = 0 ] || exit $r

echo
echo "=== 全部通った"
