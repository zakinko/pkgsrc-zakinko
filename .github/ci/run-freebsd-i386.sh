#!/bin/sh
# FreeBSD/i386 の公式 VM イメージを QEMU で起動し、その中で
# build-on-bsd.sh を走らせる。GitHub Actions の Linux runner で動かす。
#
#   sh run-freebsd-i386.sh "<PKG_OPTIONS.mule>"
#
# i386 だけは借りるあてが無い。vmactions も cross-platform-actions も
# amd64 と aarch64 と riscv64 しか作っていない。FreeBSD は公式に i386 の
# qcow2 を配っているので、それを直に使う。配っているのは 14 系までで、
# 15.0 に i386 は無い。
#
# 中に入る道が無いのが厄介なところ。イメージには鍵も cloud-init も入って
# おらず、root のパスワードは空だが sshd は空パスワードを受け付けない。
# しかもこのイメージのコンソールは ttyv0 だけで、シリアルには何も出ない。
# -vga none にしてもローダはシリアルへ落ちてこない (確認済み)。
#
# そこで QEMU のモニタから sendkey でキーを叩き込む。目で確かめられない
# ので、打つのは短い一行だけにして、あとは host の HTTP から取りに行かせる。
# 鍵さえ入れば ssh になり、NetBSD 側 (run-in-qemu.sh) と同じ形に戻る。
#
# 止め方は ACPI。モニタの quit は電源を引き抜くのと同じで、FFS が壊れる。

set -e

OPTS=${1:-"-canna -wnn4 -x11"}
TREE=$(cd "$(dirname "$0")/../.." && pwd)
REL=${FREEBSD_REL:-14.4}
WORK=${WORK:-$TREE/.vm-freebsd-i386}
PORT=${PORT:-2223}
HTTP_PORT=${HTTP_PORT:-8000}
# ローダのメニューをやり過ごすまでの待ち。KVM なら 10 秒で消えるが、
# 素の QEMU で試すときは伸ばす。
BOOT_WAIT=${BOOT_WAIT:-120}
MEM=${MEM:-3072}
DISK=${DISK:-32G}
GUEST=${GUEST:-/tmp/tree}

IMG=$WORK/freebsd-$REL-i386.qcow2
URL=https://download.freebsd.org/releases/VM-IMAGES/$REL-RELEASE/i386/Latest/FreeBSD-$REL-RELEASE-i386-ufs.qcow2.xz

mkdir -p "$WORK"
# unix socket の名前は 104 バイトまで。workspace の下に置くと、深いところに
# checkout された環境で黙って起動できなくなるので、短いところに掘る。
SOCKDIR=$(mktemp -d /tmp/mule-fbsd.XXXXXX)

echo "=== イメージを用意する ==="
if [ ! -s "$IMG" ]; then
	curl -fsSL -o "$IMG.xz" "$URL"
	xz -d "$IMG.xz"
	# 配布イメージは 6GB で、pkgsrc のツリーと依存一式には足りない。
	# 広げておけば rc.conf の growfs_enable が初回起動で / を伸ばす。
	qemu-img resize "$IMG" "$DISK"
fi
[ -s "$WORK/id" ] || ssh-keygen -q -t ed25519 -N '' -C mule-ci -f "$WORK/id"

SSH="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
     -o BatchMode=yes -o LogLevel=ERROR -o ConnectTimeout=5 \
     -i $WORK/id -p $PORT root@127.0.0.1"

HTTPD=

cleanup() {
	rc=$?
	# 作りかけは失敗しても持ち帰る。次の回がそこから始められる。
	$SSH "test -d $GUEST/.bsdcache && tar czf - -C $GUEST .bsdcache" \
		2>/dev/null | tar xzf - -C "$TREE" 2>/dev/null || true
	[ -z "$HTTPD" ] || kill "$HTTPD" 2>/dev/null || true
	if [ -S "$SOCKDIR/qmon.sock" ]; then
		echo system_powerdown | nc -U "$SOCKDIR/qmon.sock" > /dev/null 2>&1 || true
		i=0
		while [ $i -lt 90 ] && [ -s "$WORK/qemu.pid" ] && \
		    kill -0 "$(cat "$WORK/qemu.pid")" 2>/dev/null; do
			sleep 2
			i=$((i + 1))
		done
	fi
	rm -rf "$SOCKDIR"
	exit $rc
}

echo "=== 起動 ==="
rm -f "$WORK/qemu.pid"
# コンソールはシリアルに出ないが、それでも繋いで記録は取る。転けたときに
# 「何も出ていない」ことが分かるだけでも足しになる。
qemu-system-i386 \
	-machine accel=kvm:tcg -cpu max -m "$MEM" -smp 2 \
	-drive file="$IMG",if=virtio,format=qcow2 \
	-netdev user,id=n0,hostfwd=tcp:127.0.0.1:$PORT-:22 \
	-device virtio-net-pci,netdev=n0 \
	-chardev socket,id=con,path="$SOCKDIR/console.sock",server=on,wait=off,logfile="$WORK/console.log" \
	-serial chardev:con \
	-monitor unix:"$SOCKDIR/qmon.sock",server,nowait \
	-display none -daemonize -pidfile "$WORK/qemu.pid"
trap cleanup EXIT INT TERM

# ------------------------------------------------------------------
# 一行だけ打ち込むための道具。打てる文字は使うぶんしか用意していない。
sendline() {
	_s=$1
	{
		while [ -n "$_s" ]; do
			_c=$(printf '%s' "$_s" | cut -c1)
			_s=$(printf '%s' "$_s" | cut -c2-)
			case $_c in
			[a-z0-9])	echo "sendkey $_c" ;;
			' ')	echo "sendkey spc" ;;
			-)	echo "sendkey minus" ;;
			.)	echo "sendkey dot" ;;
			/)	echo "sendkey slash" ;;
			:)	echo "sendkey shift-semicolon" ;;
			'|')	echo "sendkey shift-backslash" ;;
			*)	echo "sendline に無い文字: $_c" >&2; return 1 ;;
			esac
		done
		echo "sendkey ret"
	} | nc -U "$SOCKDIR/qmon.sock" > /dev/null 2>&1
}

echo "=== 鍵を入れる ==="
mkdir -p "$WORK/serve"
cp "$WORK/id.pub" "$WORK/serve/id.pub"
cat > "$WORK/serve/s" <<SETUP
mkdir -p /root/.ssh
chmod 700 /root/.ssh
fetch -qo /root/.ssh/authorized_keys http://10.0.2.2:$HTTP_PORT/id.pub
chmod 600 /root/.ssh/authorized_keys
sysrc sshd_enable=YES
# FreeBSD の sshd は root を既定で拒む。鍵でだけ通す。ここを開けないと、
# 鍵を置いても入れない (実際にこれで止まった)。
sed -i '' -e 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' \
	/etc/ssh/sshd_config
grep -q '^PermitRootLogin' /etc/ssh/sshd_config || \
	echo 'PermitRootLogin prohibit-password' >> /etc/ssh/sshd_config
service sshd restart || service sshd onestart
# 立ったかどうかを host の HTTP ログに残す。中が見えないので、これが
# 唯一の手がかりになる。
pgrep -q sshd && fetch -qo- http://10.0.2.2:$HTTP_PORT/sshd-up > /dev/null 2>&1
pgrep -q sshd || fetch -qo- http://10.0.2.2:$HTTP_PORT/sshd-down > /dev/null 2>&1
SETUP
python3 -m http.server "$HTTP_PORT" --bind 127.0.0.1 \
	--directory "$WORK/serve" > "$WORK/httpd.log" 2>&1 &
HTTPD=$!

# ローダのメニューが出ている間に打ってはいけない。あれは一文字ずつを
# 選択として食うので、単一ユーザで起動してしまう。実際にそうなった。
# メニューは 10 秒で消えるので、それより充分あとから打ち始める。
sleep "$BOOT_WAIT"

# login が出ていなければ何も起きないだけなので、入るまで繰り返す。root に
# パスワードは無いが、訊かれた場合に備えて空の行を一つ送っておく。
i=0
until $SSH true 2>/dev/null; do
	i=$((i + 1))
	[ $i -le 30 ] || { echo "ssh が開かない"; exit 1; }
	sendline root
	sleep 2
	sendline ''
	sleep 1
	sendline "fetch -qo- http://10.0.2.2:$HTTP_PORT/s|sh"
	sleep 8
	# 何かの拍子に単一ユーザで上がっていると、network が無いので取りに
	# 来られない。exit すれば multiuser の続きが走る。取りに来た形跡が
	# 無いときだけ送る。login: に向けて打っても入り損なうだけで済む。
	grep -q 'GET /s' "$WORK/httpd.log" 2>/dev/null || sendline exit
done
kill "$HTTPD" 2>/dev/null || true
HTTPD=
$SSH "uname -a; df -h /"

# ------------------------------------------------------------------
echo "=== パッケージと検査を送り込む ==="
$SSH "rm -rf $GUEST && mkdir -p $GUEST"
tar czf - -C "$TREE" mule .github/ci \
	$([ -d "$TREE/distfiles" ] && echo distfiles) \
	$([ -d "$TREE/.bsdcache" ] && echo .bsdcache) \
	| $SSH "tar xzf - -C $GUEST"

echo "=== 組んで確かめる ==="
$SSH "sh $GUEST/.github/ci/build-on-bsd.sh '$OPTS'"
