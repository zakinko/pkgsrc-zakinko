#!/bin/sh
# FreeMiNT を ARAnyM で起動し、中に何があるかを持ち帰る。GitHub Actions の
# Linux runner で動かす。
#
#   sh run-freemint.sh
#
# pkgsrc は mk/platform/FreeMiNT.mk を持っている。動かす機械が手に入らない
# 側 (AIX, HP-UX, IRIX, Tru64, SCO, UnixWare, QNX) に並んでいるが、ここだけ
# は例外で、ARAnyM という m68k の仮想機械が FreeMiNT のために作られており、
# ライセンスの壁も無い。
#
# 使うのは AFROS 8.12。ARAnyM の側で配っている FreeMiNT 一式で、drive_c が
# そのままホストのディレクトリになる (hostfs)。中と外のやりとりにネット
# ワークもディスクイメージの細工も要らず、ホストに置いたファイルがゲスト
# から見え、ゲストが書いたものがホストから読める。
#
# ただし AFROS に開発道具は入っていない。bin にあるのは bash と ls と
# ifconfig と route だけで、コンパイラが無い。だからこの段階でやるのは
# 「何が入っているか」を確かめるところまで。pkgsrc を bootstrap する話は
# そのあと (SpareMiNT の gcc を足す) になる。
#
# 止め方は、ゲストに終わりの印を書かせてホストから殺す。ARAnyM の中の
# FreeMiNT 1.17 に halt は入っていない。

set -e

BASE=$(cd "$(dirname "$0")/../.." && pwd)
WORK=${WORK:-$BASE/.freemint}
AFROS_URL=${AFROS_URL:-https://downloads.sourceforge.net/aranym/afros/8.12/afros812.zip}
WAIT=${WAIT:-180}

MINT_CNF=drive_c/mint/1-17-cur/mint.cnf
CI=drive_c/ci

mkdir -p "$WORK"

echo "=== AFROS を用意する ==="
[ -s "$WORK/afros812.zip" ] || curl -fsSL -o "$WORK/afros812.zip" "$AFROS_URL"
rm -rf "$WORK/afros"
unzip -q -o "$WORK/afros812.zip" -d "$WORK"
cd "$WORK/afros"
mkdir -p "$CI"

# ------------------------------------------------------------------
# ゲスト側。bash しか無いので、外部コマンドを呼ばずに書く。ドライブ C は
# MiNT からは u:/c に見える (mint.cnf 自身がその書き方をしている)。
cat > "$CI/run.sh" <<'GUEST'
exec > u:/c/ci/out.txt 2>&1
echo "=== FreeMiNT の中 ==="
echo "OSTYPE=$OSTYPE MACHTYPE=$MACHTYPE HOSTTYPE=$HOSTTYPE"
echo "bash=$BASH_VERSION"

echo "--- kernel ---"
for f in u:/kern/version u:/kern/buildinfo u:/kern/sysname; do
	[ -r "$f" ] && echo "$f: $(< $f)"
done

echo "--- pkgsrc に要るもの ---"
for c in sh gcc cc make bmake gmake ar ld as awk sed tar gzip ftp curl perl python; do
	p=$(type -p "$c" 2>/dev/null)
	if [ -n "$p" ]; then echo "have $c = $p"; else echo "no   $c"; fi
done

echo "--- u:/c/bin ---"
for f in u:/c/bin/*; do echo "$f"; done

echo "--- ホストが見えているか (D は host の / ) ---"
for f in u:/d/etc/hostname u:/d/etc/hosts; do
	[ -r "$f" ] && echo "$f あり"
done

echo "=== おわり ==="
echo done > u:/c/ci/done
GUEST

# ------------------------------------------------------------------
# XaAES ではなく検査を起動する。INIT はここ一箇所で決まる。
sed 's|^INIT=.*|INIT=u:/c/bin/bash u:/c/ci/run.sh|' "$MINT_CNF" > "$MINT_CNF.new"
mv "$MINT_CNF.new" "$MINT_CNF"
grep '^INIT=' "$MINT_CNF"

# 画面もネットワークも要らない。ETH0 の bridge は tap0 を掴もうとするので
# 切る。runner に tap0 は無い。
sed -e 's|^Type = bridge|Type = none|' \
    -e 's|^GrabMouse = Yes|GrabMouse = No|' \
    -e 's|^AutoGrabMouse = Yes|AutoGrabMouse = No|' config > config.new
mv config.new config

ARANYM=$(command -v aranym-jit || command -v aranym) || {
	echo "aranym が無い"; exit 1; }

echo "=== 起動 ($ARANYM) ==="
rm -f "$CI/done" "$CI/out.txt"
SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy \
	"$ARANYM" -c config > "$WORK/aranym.log" 2>&1 &
PID=$!

i=0
while [ ! -f "$CI/done" ] && [ $i -lt "$WAIT" ]; do
	kill -0 $PID 2>/dev/null || break
	sleep 2
	i=$((i + 2))
done
kill $PID 2>/dev/null || true
sleep 1

echo "=== ARAnyM の言い分 ==="
tail -20 "$WORK/aranym.log" || true

if [ ! -s "$CI/out.txt" ]; then
	echo "=== ゲストは何も書かなかった ($i 秒待った) ==="
	exit 1
fi

echo
echo "=== ゲストから持ち帰ったもの ==="
cat "$CI/out.txt"
[ -f "$CI/done" ] || { echo "(最後まで走っていない)"; exit 1; }
