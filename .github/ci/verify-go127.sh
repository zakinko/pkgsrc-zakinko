#!/bin/sh
# lang/go127 が go-bin から一段で建ち、作った物が動くか。pkglint も見る。
#
#   sh verify-go127.sh lang/go127
#
#   1. install。log から go の連鎖を拾い、go14 が居ないこと
#   2. go127/bin/go version、hello world を build して走らせる
#   3. pkgtools/pkglint を入れて lang/go-bin と lang/go に掛け、当てる前
#      (tree-patch が .ci-orig に取った物) と比べて増えた行が無いこと
PKG=${1:-lang/go127}
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin; export PATH
T=${TMPDIR:-/tmp}
BMAKE=$PREFIX/bin/bmake
[ -x "$BMAKE" ] || BMAKE=make
cd "$TREE/$PKG" || { echo "FAIL: $TREE/$PKG が無い"; exit 1; }
rc=0
echo "--- $PKG ($(uname -s) $(uname -r) / $(uname -m)) ---"

echo "########## 1. install ##########"
if $BMAKE install > "$T/go127-install.log" 2>&1; then
	echo "  ok install"
else
	echo "!! install が落ちた"; rc=1
	_first=$(grep -n '\*\*\* Error code' "$T/go127-install.log" | head -1 | cut -d: -f1)
	[ -n "$_first" ] && sed -n "$((_first > 40 ? _first - 40 : 1)),${_first}p" "$T/go127-install.log" | cut -c1-200 | sed 's/^/     /'
fi
_chain=$(grep -E '===> Installing dependencies for (go-bin|go14|go[0-9]+)-' "$T/go127-install.log" |
	sed 's/.*for //' | tr '\n' ' ')
echo "  go の連鎖: ${_chain:-(log に無い。既に入っていた)}"
case " $_chain " in
*" go14-"*) echo "!! go14 が引かれた"; rc=1 ;;
esac
grep -q 'go-bin-' "$T/go127-install.log" && echo "  ok 底は go-bin"

echo "########## 2. 動くか ##########"
GO=$PREFIX/go127/bin/go
if [ -x "$GO" ]; then
	echo "  $($GO version 2>&1)"
	D=$T/go127-hello; rm -rf "$D"; mkdir -p "$D"
	cat > "$D/main.go" <<'GOEOF'
package main

import (
	"fmt"
	"os"
	"runtime"
)

func main() {
	h, _ := os.Hostname()
	fmt.Printf("hello from %s/%s on %s\n", runtime.GOOS, runtime.GOARCH, h)
}
GOEOF
	( cd "$D" && HOME=$D GOFLAGS=-mod=mod GOPATH=$D/gopath GOCACHE=$D/cache "$GO" mod init hello > /dev/null 2>&1 &&
	  HOME=$D GOPATH=$D/gopath GOCACHE=$D/cache "$GO" build -o hello . ) > "$D/build.log" 2>&1
	if [ -x "$D/hello" ]; then
		_out=$("$D/hello" 2>&1); echo "  $_out"
		case "$_out" in "hello from $(uname -s | tr 'A-Z' 'a-z')/"*) echo "  ok build した物が走る" ;; *) echo "!! 出力が違う"; rc=1 ;; esac
	else
		echo "!! hello が build できない"; tail -10 "$D/build.log"; rc=1
	fi
else
	echo "!! $GO が無い"; rc=1
fi

echo "########## 3. pkglint ##########"
if ( cd "$TREE/pkgtools/pkglint" && $BMAKE install > "$T/pkglint-install.log" 2>&1 ); then
	for d in lang/go-bin lang/go; do
		( cd "$TREE/$d" && pkglint 2>&1 ) > "$T/pkglint.after.$(basename $d)" || true
	done
	if [ -d "$TREE/.ci-orig" ]; then
		# 当てる前の物と入れ替えて同じ pkglint を掛け、増えた行だけ見る
		for f in lang/go-bin/Makefile lang/go-bin/distinfo lang/go/bootstrap.mk; do
			cp "$TREE/$f" "$TREE/.ci-orig/$f.patched"; cp "$TREE/.ci-orig/$f" "$TREE/$f"
		done
		for d in lang/go-bin lang/go; do
			( cd "$TREE/$d" && pkglint 2>&1 ) > "$T/pkglint.before.$(basename $d)" || true
		done
		for f in lang/go-bin/Makefile lang/go-bin/distinfo lang/go/bootstrap.mk; do
			cp "$TREE/.ci-orig/$f.patched" "$TREE/$f"
		done
		# 行番号は捨てて比べる。当て物で行がずれると、元から在る
		# WARN (bootstrap.mk の go14-1.4* の版の書き方) が「増えた行」に
		# 見える (run 35196319109)。
		for d in go-bin go; do
			sed 's/^\([A-Z]*: [^:]*\):[0-9]*:/\1:/' "$T/pkglint.before.$d" > "$T/pkglint.before.$d.nl"
			_new=$(grep -vE '^Looks fine|^[0-9]+ (warnings|errors)' "$T/pkglint.after.$d" |
				sed 's/^\([A-Z]*: [^:]*\):[0-9]*:/\1:/' | grep -vxF -f "$T/pkglint.before.$d.nl" || true)
			if [ -n "$_new" ]; then echo "!! pkglint lang/$d に増えた行:"; echo "$_new" | sed 's/^/     /'; rc=1
			else echo "  ok pkglint lang/$d: 当てる前から増えた行は無い ($(wc -l < "$T/pkglint.after.$d" | tr -d ' ') 行)"; fi
		done
	else
		for d in go-bin go; do echo "  -- pkglint lang/$d"; sed 's/^/     /' "$T/pkglint.after.$d"; done
	fi
else
	echo "  (pkglint が入らなかった。見ない)"; tail -5 "$T/pkglint-install.log"
fi

[ $rc -eq 0 ] && echo "RESULT: go127 は go-bin から建ち、作った物が走る" || echo "RESULT: 通らなかったものがある (上を読む)"
exit $rc
