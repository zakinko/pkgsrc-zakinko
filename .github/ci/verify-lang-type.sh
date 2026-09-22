#!/bin/sh
# GO_TYPE と RUST_TYPE が、binary の在る箱では bin を選び、無い箱では
# 黙って src に落ちることを見る。木への当て物は TREE_PATCH で当たっている。
#
# 「無い箱で落ちる」を測るのが肝。mk.conf に一度書いた設定が、別の箱で
# その言語の package を全部壊さないことの確認にあたる。
set -e
LC_ALL=C; export LC_ALL
OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin:/usr/local/bin
export PATH
if [ -x "$PREFIX/bin/bmake" ]; then PKGMAKE="$PREFIX/bin/bmake"
elif [ "$OS" = NetBSD ]; then PKGMAKE=make
else PKGMAKE=bmake; fi
rc=0

# 実在の package の場から訊く。lang/go-bin 自身は go を使わないので、
# go を使う package を一つ選ぶ。
GOPKG=$TREE/devel/git-lfs
RUSTPKG=$TREE/textproc/ripgrep

sv() { ( cd "$1" && shift && $PKGMAKE show-var VARNAME="$1" "$@" ) 2>/dev/null | tail -1; }
svv() { d=$1; shift; v=$1; shift; ( cd "$d" && $PKGMAKE show-var VARNAME="$v" "$@" ) 2>/dev/null | tail -1; }

echo "########## 箱 ##########"
PLAT=$(svv "$TREE/pkgtools/digest" MACHINE_PLATFORM)
echo "  MACHINE_PLATFORM: $PLAT"

if [ -d "$GOPKG" ]; then
	echo "########## GO_TYPE ##########"
	sup=$(svv "$GOPKG" GO_BIN_SUPPORTED)
	echo "  GO_BIN_SUPPORTED    : $sup"
	echo "  GO_TYPE 無指定 の GO : $(svv "$GOPKG" GO)"
	echo "  GO_TYPE 無指定 の dep: $(svv "$GOPKG" GO_PACKAGE_DEP)"
	gb=$(svv "$GOPKG" GO GO_TYPE=bin)
	db=$(svv "$GOPKG" GO_PACKAGE_DEP GO_TYPE=bin)
	echo "  GO_TYPE=bin の GO    : $gb"
	echo "  GO_TYPE=bin の dep   : $db"
	case $sup in
	yes)	case $db in *go-bin*) echo "  -> bin を選んだ (対応する箱なので正しい)" ;;
		         *) echo "  !! 対応する箱なのに bin にならない"; rc=1 ;; esac ;;
	no)	case $db in *go-bin*) echo "  !! 対応しない箱なのに go-bin を要求している"; rc=1 ;;
		         *) echo "  -> src に落ちた (対応しない箱なので正しい)" ;; esac ;;
	*)	echo "  !! GO_BIN_SUPPORTED が yes/no でない: $sup"; rc=1 ;;
	esac
else
	echo "  (devel/git-lfs が無いので GO_TYPE は見ない)"
fi

if [ -d "$RUSTPKG" ]; then
	echo "########## RUST_TYPE ##########"
	sup=$(svv "$RUSTPKG" PLATFORM_SUPPORTS_RUST_BIN)
	echo "  PLATFORM_SUPPORTS_RUST_BIN: $sup"
	for t in "" bin; do
		if [ -z "$t" ]; then lbl="無指定"; d=$(svv "$RUSTPKG" BUILD_DEPENDS)
		else lbl="RUST_TYPE=bin"; d=$(svv "$RUSTPKG" BUILD_DEPENDS RUST_TYPE=bin); fi
		printf '  %-14s の BUILD_DEPENDS: %s\n' "$lbl" "$(echo "$d" | tr ' ' '\n' | grep -i rust | tr '\n' ' ')"
	done
	db=$(svv "$RUSTPKG" BUILD_DEPENDS RUST_TYPE=bin)
	case $sup in
	yes)	case $db in *rust-bin*) echo "  -> bin を選んだ (対応する箱なので正しい)" ;;
		         *) echo "  !! 対応する箱なのに bin にならない"; rc=1 ;; esac ;;
	no)	case $db in *rust-bin*) echo "  !! 対応しない箱なのに rust-bin を要求している"; rc=1 ;;
		         *) echo "  -> src に落ちた (対応しない箱なので正しい)" ;; esac ;;
	*)	echo "  !! PLATFORM_SUPPORTS_RUST_BIN が yes/no でない: $sup"; rc=1 ;;
	esac
else
	echo "  (textproc/ripgrep が無いので RUST_TYPE は見ない)"
fi

echo
[ $rc = 0 ] && echo "== lang-type: 期待どおり ($PLAT)" || echo "== lang-type: FAILURES on $PLAT"
exit $rc
