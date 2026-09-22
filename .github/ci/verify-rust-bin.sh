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

sv() { ( cd "$D" && $PKGMAKE show-var VARNAME="$1" ) 2>/dev/null | tail -1; }

echo "########## この箱を pkgsrc がどう綴るか ##########"
PLAT=$(sv MACHINE_PLATFORM)
printf '  %-22s %s\n' OPSYS         "$(sv OPSYS)"
printf '  %-22s %s\n' OS_VERSION    "$(sv OS_VERSION)"
printf '  %-22s %s\n' MACHINE_ARCH  "$(sv MACHINE_ARCH)"
printf '  %-22s %s\n' OS_VARIANT    "$(sv OS_VARIANT)"
printf '  %-22s %s\n' MACHINE_PLATFORM "$PLAT"
printf '  %-22s %s\n' PKGNAME       "$(sv PKGNAME)"

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
fi

if [ $rc = 0 ]; then
	echo "########## 入った rustc を動かす ##########"
	RUSTC=$PREFIX/bin/rustc
	CARGO=$PREFIX/bin/cargo
	if [ -x "$RUSTC" ]; then
		echo "  rustc: $("$RUSTC" --version 2>&1)"
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
