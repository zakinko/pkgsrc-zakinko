#!/bin/sh
# Solaris/illumos で patchelf が ELF を壊すのかを切り分ける。
#
# 何を追っているか。OpenIndiana では upstream の rust binary が
# libgcc_s.so.1 を既定の実行時 path で見つけられない (あちらは
# /usr/gcc/<ver>/lib にしか置かない。OmniOS は在る)。rust-bin の
# fix-relative-rpath が書く rpath にその directory を足す版を作って測ったら、
# 症状が悪化した。
#
#   足す前   ld.so.1: rustc: fatal: libgcc_s.so.1: open failed  <- 実行できている
#   足した後 rustc: cannot execute [Invalid ...]
#            ldd: rustc: execution failed due to signal 9        <- 壊れている
#
# rpath 自体は正しく書けていた (elfdump -d が読める)。だから壊しているのは
# 書いた中身ではなく書く行為の側で、patchelf は Linux の道具である。
#
# ただし「patchelf が Solaris で駄目」と断じるには早い。候補が三つ在って、
# 一つの run では分かれていない。
#
#   (a) rpath に .. が入っていること
#       cc -print-file-name が返すのは
#       /usr/gcc/14/lib/gcc/x86_64-pc-solaris2.11/14.3.0/../../../amd64
#   (b) rpath が長くなって section を伸ばす必要が出たこと
#   (c) patchelf が Solaris の ELF を編集すること自体
#
# 四つの写しを作って、上の三つを分けて測る。長さだけを揃えた対照 (d) を
# 置くのが要点 — 置かないと (a) と (b) が同じ顔で出る。
set -e
PREFIX=${PREFIX:-/usr/pkg}
BIN=${1:-$PREFIX/bin/rustc}
W=${2:-/var/tmp/solaris-rpath-probe}

case $(uname -s) in
SunOS) ;;
*)	echo "  (SunOS 専用の測定なので何もしない)"; exit 0 ;;
esac

PATCHELF=$PREFIX/bin/patchelf
for _p in "$PATCHELF" "$BIN"; do
	[ -x "$_p" ] || { echo "  !! $_p が無い。測れない"; exit 0; }
done

rm -rf "$W"; mkdir -p "$W"

# 実際に libgcc_s が在る directory を、正規化した形と生の形の両方で用意する。
RAW=$(${CC:-gcc} -print-file-name=libgcc_s.so.1 2>/dev/null || echo "")
case $RAW in
/*)	RAWDIR=$(dirname "$RAW") ;;
*)	echo "  !! cc が libgcc_s の在処を答えない。測れない"; exit 0 ;;
esac
# .. を畳んだ形。cd で解決させる (realpath が無い箱が在る)。
NORMDIR=$(cd "$RAWDIR" 2>/dev/null && pwd) || NORMDIR=$RAWDIR
echo "  cc が答える生の path : $RAWDIR"
echo "  .. を畳んだ path     : $NORMDIR"

# (d) 長さだけを $RAWDIR に合わせた、.. を含まない詰め物。
#     $NORMDIR の後ろを 'x' で埋める。
_pad=$NORMDIR
while [ ${#_pad} -lt ${#RAWDIR} ]; do _pad="${_pad}x"; done
PADDIR=$_pad

# 分類する。三つの状態を混ぜない。
classify() {  # $1 = 試す binary
	_out=$("$1" --version 2>&1 </dev/null || true)
	case $_out in
	*"cannot execute"*|*"Invalid"*|*"not an ELF"*|*"bad ELF"*)
		echo "壊れている  ($_out)" ;;
	*libgcc_s*|*"open failed"*|*"fatal:"*)
		echo "実行できるが library が足りない  ($_out)" ;;
	*rustc*|*[0-9].[0-9]*)
		echo "動く  ($_out)" ;;
	*)	echo "不明  ($_out)" ;;
	esac
}

run_case() {  # $1 = 名前  $2 = 設定する rpath (空なら patchelf を呼ばない)
	_n=$1; _r=$2
	cp "$BIN" "$W/$_n"
	if [ -n "$_r" ]; then
		if ! "$PATCHELF" --force-rpath --set-rpath "$_r" "$W/$_n" 2>"$W/$_n.err"; then
			echo "  $_n: patchelf 自体が落ちた: $(head -1 "$W/$_n.err")"
			return
		fi
	fi
	printf '  %-22s len=%-3s %s\n' "$_n" "${#_r}" "$(classify "$W/$_n")"
	# rpath が実際に何になったかも出す。書けたことと動くことは別。
	if [ -n "$_r" ]; then
		elfdump -d "$W/$_n" 2>/dev/null |
			awk '/RPATH|RUNPATH/ {print "      -> " $2 " " $NF}' | head -2 || true
	fi
}

echo
echo "  --- 四つの写しで測る (as-installed / 正規化 / 生 / 長さだけ揃えた対照)"
# 入っている物そのまま。patchelf は既に一度当たっている (${PREFIX}/lib)。
run_case as-installed ""
run_case norm         "$PREFIX/lib:$NORMDIR"
run_case raw-dotdot   "$PREFIX/lib:$RAWDIR"
run_case pad-same-len "$PREFIX/lib:$PADDIR"

echo
echo "  --- 読み方"
echo "      norm が動いて raw-dotdot が壊れる     -> .. が原因"
echo "      norm も壊れて pad-same-len も壊れる   -> 長さ、または patchelf 全般"
echo "      norm が動いて pad-same-len が壊れる   -> 長さ"
echo "      as-installed も壊れている             -> patchelf 全般 (rpath に依らない)"
