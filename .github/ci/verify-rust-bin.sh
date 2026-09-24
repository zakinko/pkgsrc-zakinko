#!/bin/sh
# lang/rust-bin を建てて入れ、その箱の rustc が本当に動くところまで見る。
#
# 見るもの:
#   この箱を pkgsrc がどう綴るか (ONLY_FOR_PLATFORM の当て先)
#   上流の binary がこの箱の分だけ取られるか
#   入った rustc が version を答え、実際に program を建てて走らせるか
#
# go-bin と同じ形にしてある。違うのは、rust-bin が上流の配布物と
# he@NetBSD.org の作った物の二系統から取ること。
set -e
# 展開する物に非 ASCII の名前が入っていると、C locale の bsdtar が落ちる。
# go の tarball で実際に踏んだので、こちらでも UTF-8 があれば使う。
LC_ALL=C; export LC_ALL
for _l in C.UTF-8 en_US.UTF-8; do
	if locale -a 2>/dev/null | grep -qx "$_l"; then LC_ALL=$_l; break; fi
done
export LC_ALL

PKGDIR=${1:-lang/rust-bin}
OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin:/usr/local/bin
export PATH
unset PKG_PATH
if [ -x "$PREFIX/bin/bmake" ]; then PKGMAKE="$PREFIX/bin/bmake"
elif [ "$OS" = NetBSD ]; then PKGMAKE=make
else PKGMAKE=bmake; fi
D=$TREE/$PKGDIR
W=/var/tmp/rust-bin-check
rc=0
mkdir -p "$W"

# show-var が落ちると bmake は stderr にだけ文句を言い、stdout は空になる。
# 2>/dev/null で捨てると「値が bmake: stopped making ...」という形で
# 失敗が値の顔をして出てくる (run 35741763877 で実際にそうなった)。
# 落ちたら空を返し、下で一度だけ理由を出す。
SV_ERR=
sv() {
	_o=$( cd "$D" && $PKGMAKE show-var VARNAME="$1" 2>"$W/sv.err" ) || {
		[ -n "$SV_ERR" ] || SV_ERR=$(cat "$W/sv.err")
		echo "(取れない)"
		return 0
	}
	printf '%s\n' "$_o" | tail -1
}

echo "########## この箱を pkgsrc がどう綴るか ##########"
PLAT=$(sv MACHINE_PLATFORM)
printf '  %-22s %s\n' OPSYS         "$(sv OPSYS)"
printf '  %-22s %s\n' OS_VERSION    "$(sv OS_VERSION)"
printf '  %-22s %s\n' MACHINE_ARCH  "$(sv MACHINE_ARCH)"
printf '  %-22s %s\n' OS_VARIANT    "$(sv OS_VARIANT)"
printf '  %-22s %s\n' MACHINE_PLATFORM "$PLAT"
printf '  %-22s %s\n' PKGNAME       "$(sv PKGNAME)"
if [ -n "$SV_ERR" ]; then
	echo "  !! show-var が落ちている。Makefile が読めていない:"
	printf '%s\n' "$SV_ERR" | sed 's/^/     /' | head -20
	rc=1
fi

# Solaris では「入らないこと」が正しい。当て物は
#
#   .if ${OS_VARIANT:U} != "Solaris"
#   ONLY_FOR_PLATFORM+=	SunOS-*-x86_64
#   .endif
#
# という条件を持っているのに、その条件を走らせる箱が matrix に無かった。
# 条件を含む diff を、条件を一度も撃たずに送る形だったので閉じる。
#
# 上流が出しているのは x86_64-unknown-illumos の tarball だけで、Solaris 向けは
# 無い。それが Solaris で動くかどうかは測っていないので、動かないとは書かない。
# 測るのは「この package が Solaris を名乗り出ないこと」— 当て物が作る挙動
# そのもの。
if [ "$OS" = SunOS ] && [ "$(sv OS_VARIANT)" = Solaris ]; then
	echo "########## Solaris では名乗り出ないこと ##########"
	OFP=$(sv ONLY_FOR_PLATFORM)
	echo "  ONLY_FOR_PLATFORM: $OFP"
	case $OFP in
	*SunOS*)
		echo "  !! Solaris なのに SunOS が ONLY_FOR_PLATFORM に入っている" >&2
		rc=1 ;;
	*)	echo "  ok SunOS は入っていない" ;;
	esac
	# 建てようとして拒まれることまで見る。変数が正しくても、実際に
	# 止まるかは別。
	if ( cd "$D" && $PKGMAKE install > "$W/solaris.log" 2>&1 ); then
		echo "  !! install が通ってしまった。Solaris へ配られている" >&2
		rc=1
	elif grep -qE 'not available for|ONLY_FOR_PLATFORM|NOT_FOR_PLATFORM' "$W/solaris.log"; then
		echo "  ok platform が理由で止まった:"
		grep -nE 'not available for|ONLY_FOR_PLATFORM|NOT_FOR_PLATFORM' "$W/solaris.log" |
			sed 's/^/     /' | head -3
	else
		echo "  ?? 止まったが platform が理由ではない。これは当て物の証明にならない" >&2
		tail -20 "$W/solaris.log" | sed 's/^/     /'
		rc=1
	fi
	echo
	echo "== rust-bin: Solaris では配られない ($PLAT) rc=$rc"
	exit $rc
fi

echo "########## 取られる配布物 ##########"
DF=$(sv DISTFILES)
echo "  DISTFILES: $DF"
n=0
for f in $DF; do n=$((n + 1)); done
if [ "$n" != 1 ]; then
	echo "  !! この箱の分だけで 1 個のはずが $n 個ある"
	rc=1
fi

echo "########## 建てて入れる ##########"
if ( cd "$D" && $PKGMAKE install > "$W/install.log" 2>&1 ); then
	echo "  install できた"
else
	echo "  !! install できない"
	tail -40 "$W/install.log"
	rc=1
	# Darwin では install_name_tool が load command を伸ばせずに止まる。
	#
	#   error: install_name_tool: changing install names or rpaths can't be
	#   redone ... because larger updated load commands do not fit
	#
	# @rpath (6 字) を ${PREFIX}/lib (/opt/pkg では 12 字) に書き換えるので
	# 一つにつき 6 byte 伸び、header の余白を超える。aarch64 では収まっていた。
	#
	# 直し方を決める前に、上流が何を持っているかを読む。LC_RPATH が既に
	# 在るなら @rpath を潰す必要は無く、足りない分を -add_rpath で一本
	# 加えるだけで済む — そちらなら伸びるのは一箇所。無いなら別の手が要る。
	# 読まずに -add_rpath へ替えると、必要な書き換えまで落とす。
	if [ "$OS" = Darwin ]; then
		echo "  --- 上流が持っている load command を読む"
		_wrk=$(sv WRKSRC)
		for _f in "$_wrk/rustc/bin/rustc" "$_wrk/rust-std-$(sv RUST_ARCH)/lib/rustlib/$(sv RUST_ARCH)/lib"/libstd-*.dylib; do
			[ -e "$_f" ] || continue
			echo "      == ${_f#$_wrk/}"
			otool -l "$_f" 2>/dev/null |
				awk '/LC_RPATH/,0' | grep -m4 -E 'LC_RPATH|path ' | sed 's/^/         /'
			echo "         -- install name と依存"
			otool -XL "$_f" 2>/dev/null | head -6 | sed 's/^/         /'
			echo "         -- header の余白 (sizeofcmds と最初の section の間)"
			otool -h "$_f" 2>/dev/null | tail -2 | sed 's/^/         /'
			break
		done
		echo "  --- 伸びる量"
		_new="$PREFIX/lib"
		printf '         @rpath=%s  %s=%s  一つにつき +%s byte\n' \
			6 "$_new" "${#_new}" "$(( ${#_new} - 6 ))"
	fi
fi

if [ $rc = 0 ]; then
	echo "########## 入った rustc を動かす ##########"
	RUSTC=$PREFIX/bin/rustc
	CARGO=$PREFIX/bin/cargo
	if [ -x "$RUSTC" ]; then
		# 名前ではなく入った実体を見る。木の変数が正しくても patchelf が
		# 書けていなければ意味が無い。Solaris ではここで「書けているのに
		# 実行できない」が出た。
		echo "  --- 入った rustc の RUNPATH"
		( elfdump -d "$RUSTC" 2>/dev/null | grep -iE 'RUNPATH|RPATH' \
		  || readelf -d "$RUSTC" 2>/dev/null | grep -iE 'RUNPATH|RPATH' \
		  || echo "(読めなかった)" ) | sed 's/^/      /'
		if _v=$("$RUSTC" --version 2>&1); then
			echo "  rustc: $_v"
		else
			echo "  !! rustc が起動しない: $_v"
			rc=1
			# 「無い」と言われた library が本当に無いのか、在るのに
			# 見えていないのかは別の話。ldd と在処を出して分ける。
			# OpenIndiana は libgcc_s.so.1、NetBSD/riscv64 は
			# libatomic.so.3 で、どちらも package が依存に挙げて
			# いない形に見える (run 35760404446)。
			echo "  --- ldd $RUSTC"
			(ldd "$RUSTC" 2>&1 || true) | sed 's/^/      /' | head -30
			# Solaris/illumos では「壊れている」と「library が
			# 足りない」を混ぜない。rpath に libgcc_s の在処を足す版を
			# 作ったら、後者が前者に変わった (ldd が signal 9 で死ぬ)。
			# patchelf は Linux の道具なので、Solaris の ELF を編集する
			# こと自体が壊しているのかを切り分ける。
			if [ "$OS" = SunOS ]; then
				echo "  --- patchelf と rpath の切り分け"
				sh "$(dirname "$0")/probe-solaris-rpath.sh" "$RUSTC" || true
			fi
			for _l in libgcc_s.so.1 libatomic.so.3 libstdc++.so.6; do
				echo "  --- $_l を箱の中で探す"
				find /usr /opt "$PREFIX" -name "$_l*" 2>/dev/null |
					sed 's/^/      /' | head -6
			done
			echo "  --- LD_LIBRARY_PATH=[${LD_LIBRARY_PATH:-未設定}]"
		fi
	else
		echo "  !! $RUSTC が無い"; rc=1
	fi
	[ -x "$CARGO" ] && echo "  cargo: $("$CARGO" --version 2>&1)"

	# version を答えるのと program が建つのは別。実際に建てて走らせる。
	if [ -x "$RUSTC" ]; then
		cat > "$W/hello.rs" <<'RS'
fn main() {
    println!("ok {} {}", std::env::consts::OS, std::env::consts::ARCH);
}
RS
		if ( cd "$W" && "$RUSTC" -O hello.rs -o hello > "$W/rustc.log" 2>&1 ); then
			echo "  建てた program: $("$W/hello" 2>&1)"
		else
			echo "  !! rustc が program を建てられない"
			tail -30 "$W/rustc.log"
			rc=1
		fi
	fi
fi

echo
if [ $rc = 0 ]; then
	echo "== rust-bin: 建って動いた ($PLAT)"
else
	echo "== rust-bin: FAILURES on $PLAT"
fi
exit $rc
