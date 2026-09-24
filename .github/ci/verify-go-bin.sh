#!/bin/sh
# zakinko/go-bin を建てて入れ、その箱の go が本当に動くところまで見る。
#
# 見るもの:
#   この箱を pkgsrc がどう綴るか (ONLY_FOR_PLATFORM の当て先)
#   上流の binary がこの箱の分だけ取られるか
#   入った go が version を答え、実際に program を建てるか
set -e
# 出力を C で読みたいが、C のままだと展開が通らない。go の tarball には
# go/test/fixedbugs/issue27836.dir/{THORN}foo.go など U+00DE を含む名前が
# 二本入っていて、libarchive の bsdtar は archive が UTF-8 だと言っている
# 名前を現行 locale へ変換できないと落ちる (illumos で実測)。既定の locale
# が C の箱はそのまま踏むので、UTF-8 があれば使い、無ければ C のまま進めて
# 何を持っていたかを記録に残す。
LC_ALL=C; export LC_ALL
for _l in C.UTF-8 en_US.UTF-8; do
	if locale -a 2>/dev/null | grep -qx "$_l"; then
		LC_ALL=$_l; break
	fi
done
export LC_ALL
echo "  locale: LC_ALL=$LC_ALL (この箱にある UTF-8: $(locale -a 2>/dev/null | grep -i 'utf-*8' | tr '\n' ' ')) "
OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin:/usr/local/bin
export PATH
unset PKG_PATH
if [ -x "$PREFIX/bin/bmake" ]; then PKGMAKE="$PREFIX/bin/bmake"
elif [ "$OS" = NetBSD ]; then PKGMAKE=make
else PKGMAKE=bmake; fi
rc=0
DIR=$TREE/zakinko/go-bin
T=${TMPDIR:-/tmp}/go-bin-v.$$; mkdir -p "$T"

sv() { ( cd "$DIR" && $PKGMAKE show-var VARNAME="$1" ) 2>/dev/null | tail -1; }

echo "########## この箱の名乗り ##########"
printf '  uname          : %s %s %s\n' "$(uname -s)" "$(uname -r)" "$(uname -m)"
for v in OPSYS MACHINE_ARCH MACHINE_PLATFORM; do
	printf '  %-15s: %s\n' "$v" "$(sv $v)"
done

echo "########## go-bin から見て ##########"
PLAT=$(sv MACHINE_PLATFORM)
SUP=$(sv PLATFORM_SUPPORTS_GO_BIN)
DF=$(sv DISTFILES)
printf '  PLATFORM_SUPPORTS_GO_BIN: %s\n' "$SUP"
printf '  PKGNAME         : %s\n' "$(sv PKGNAME)"
printf '  DISTFILES       : %s\n' "$DF"
n=$(echo "$DF" | tr ' ' '\n' | grep -c . || true)
if [ "$SUP" = yes ]; then
	[ "$n" = 1 ] || { echo "  !! 対応と言いながら DISTFILES が $n 本 (1 本であるべき)"; rc=1; }
else
	echo "  この箱は go-bin の対象外。建てずに終わる"
	rm -rf "$T"; echo; echo "== go-bin: 対象外 ($PLAT)"; exit 0
fi

echo "########## 建てて入れる ##########"
if ( cd "$DIR" && $PKGMAKE install ); then
	echo "  install できた"
else
	echo "  !! install できない"; rc=1
	rm -rf "$T"; echo; echo "== go-bin: FAILURES on $PLAT"; exit 1
fi

echo "########## 入った go を動かす ##########"
GO=$PREFIX/go-bin/bin/go
if [ ! -x "$GO" ]; then echo "  !! $GO が無い"; rc=1
else
	v=$("$GO" version 2>&1 || true)
	echo "  go version: $v"
	case $v in
	*"go1.27.1"*) : ;;
	*) echo "  !! 1.27.1 と名乗らない"; rc=1 ;;
	esac
	# 上流の binary は GOOS/GOARCH を自分で知っている。箱と食い違えば
	# ここで出る。
	echo "  go env GOOS/GOARCH: $("$GO" env GOOS 2>/dev/null)/$("$GO" env GOARCH 2>/dev/null)"
	# 実際に建てて走らせる。version を答えるだけでは動いたと言えない。
	mkdir -p "$T/h" && cd "$T/h"
	cat > main.go <<'GOF'
package main
import ("fmt"; "runtime")
func main(){ fmt.Printf("ok %s/%s %s\n", runtime.GOOS, runtime.GOARCH, runtime.Version()) }
GOF
	( echo 'module h'; echo 'go 1.21' ) > go.mod
	if env HOME="$T/h" GOCACHE="$T/gocache" GOFLAGS=-mod=mod "$GO" build -o hello . 2>"$T/build.err"; then
		out=$(./hello 2>&1 || true)
		echo "  建てた program: $out"
		case $out in ok\ *) : ;; *) echo "  !! 走らない"; rc=1 ;; esac
	else
		echo "  !! go build が通らない"; rc=1
		sed 's/^/    /' "$T/build.err" | head -6
	fi
	cd /
fi

rm -rf "$T"
echo
[ $rc = 0 ] && echo "== go-bin: 建って動いた ($PLAT)" || echo "== go-bin: FAILURES on $PLAT"
exit $rc
