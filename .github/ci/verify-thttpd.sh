#!/bin/sh
# zakinko/thttpd を pkgsrc で建てて入れ、三つの CVE をこの箱で踏めるだけ踏む。
# build-on-bsd.sh が pkgsrc を bootstrap した後、PKGS='thttpd' で呼ぶ。
#
#   sh verify-thttpd.sh [OPTS(無視)]
#
# 見るもの:
#   pkgsrc で建って入る (どの箱でも)
#   CVE-2009-4491 (log injection)  pkgsrc で入れた thttpd で。上流に修正が
#                                  無いので、回せる箱すべてで撃つ
#   CVE-2012-5640 (crypt NULL)     NULL を返す箱は native、返さない箱は shim
#   CVE-2007-0158 (underflow)      空 symlink + ASan が動く箱で、当て物あり/
#                                  無しを ASan で建てて full process を撃つ。
#                                  空 symlink を作れない箱 (Linux) と ASan が
#                                  ASLR で動かない箱 (NetBSD) は理由付きで skip
set -e
OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin:/usr/local/bin
export PATH
unset PKG_PATH
rc=0
T=${TMPDIR:-/tmp}/thttpd-v.$$; mkdir -p "$T"

if [ "$OS" = NetBSD ]; then PKGMAKE=make; else PKGMAKE=bmake; fi
command -v $PKGMAKE >/dev/null 2>&1 || PKGMAKE="$PREFIX/bin/bmake"

########################################################################
echo "########## build+install via pkgsrc ##########"
DIR=$TREE/zakinko/thttpd
( cd "$DIR" && [ -f distinfo ] || $PKGMAKE makesum >/dev/null 2>&1 || true )
( cd "$DIR" && $PKGMAKE install ) || { echo "!! pkgsrc build/install failed"; exit 1; }
BIN=$PREFIX/sbin/thttpd
[ -x "$BIN" ] || BIN=$PREFIX/bin/thttpd
echo "installed: $BIN"

serve() { # $1=label  $2=binary  $3=preload  -> code_ alive_ log_
	D="$T/d-$1"; rm -rf "$D"; mkdir -p "$D/priv"
	echo hi > "$D/index.html"; echo secret > "$D/priv/index.html"
	printf 'bob:$9$notasalt\n' > "$D/priv/.htpasswd"
	env $3 "$2" -p 18091 -d "$D" -l "$D/log" -i "$D/pid" -D -nos > "$D/out" 2>&1 &
	sleep 1
	curl -s -o /dev/null "http://127.0.0.1:18091/x" \
	    -H "Referer: $(printf 'R\033]0;X\007')" -A "$(printf 'U\033[2J')" 2>/dev/null || true
	code=$(curl -s -o /dev/null -w '%{http_code}' -u bob:pw http://127.0.0.1:18091/priv/ 2>/dev/null || echo none)
	sleep 0.4
	if kill -0 "$(cat "$D/pid" 2>/dev/null)" 2>/dev/null; then alive=1; else alive=0; fi
	kill "$(cat "$D/pid" 2>/dev/null)" 2>/dev/null || true
	eval "code_$1=$code alive_$1=$alive log_$1=$D/log"
}

########################################################################
# CVE-2009-4491: log injection (pkgsrc で入れた当て物入りの thttpd で)
echo "########## CVE-2009-4491 (log injection) on $OS ##########"
serve patched "$BIN" ""
if grep -q "$(printf '\033')" "$log_patched" 2>/dev/null; then echo "  !! patched log に生の ESC"; rc=1
else echo "  patched: 生の ESC なし"; fi
if grep -q '\\x1b' "$log_patched" 2>/dev/null; then echo "  patched: \\x1b に escape されている"
else echo "  !! patched log に \\x1b が無い"; rc=1; fi

# 素の 2.29 (tarball) と対照する。上流に修正が無いので、素で ESC が生で
# 入ることをこの箱でも見せる。
DL="curl -sSLO"; command -v curl >/dev/null 2>&1 || DL="wget -q"
( cd "$T" && $DL https://www.acme.com/software/thttpd/thttpd-2.29.tar.gz )
sbuild() { # $1=label $2=applyPatch(yes/no) $3=CCflags -> $T/$1/thttpd
	rm -rf "$T/$1"; ( cd "$T" && gzip -dc thttpd-2.29.tar.gz | tar xf - && mv thttpd-2.29 "$1" )
	[ "$2" = no ] || ( cd "$T/$1" && patch -p0 -f < "$DIR/patches/patch-libhttpd.c" >/dev/null )
	( cd "$T/$1" && ./configure >/dev/null 2>&1 && make CC="${CC:-cc} $3" thttpd >bl.log 2>&1 )
	test -x "$T/$1/thttpd"
}
if sbuild stock no ""; then
	serve stock "$T/stock/thttpd" ""
	if grep -q "$(printf '\033')" "$log_stock" 2>/dev/null; then echo "  stock: 生の ESC が log に入る (再現)"
	else echo "  !! stock で ESC が再現しない"; rc=1; fi
else echo "  (素の 2.29 を建てられず、対照は略)"; fi

########################################################################
# CVE-2012-5640: crypt() NULL
echo "########## CVE-2012-5640 (crypt NULL) on $OS ##########"
cat > "$T/cr.c" <<'C'
#include <stdio.h>
#include <unistd.h>
#if defined(__linux__)
#include <crypt.h>
#endif
int main(void){char*r=crypt("pw","$9$notasalt");printf("%s\n",r?r:"NULL");return r?1:0;}
C
NULLCRYPT=0
if ${CC:-cc} -o "$T/cr" "$T/cr.c" -lcrypt 2>/dev/null || ${CC:-cc} -o "$T/cr" "$T/cr.c" 2>/dev/null; then
	"$T/cr" >/dev/null 2>&1 || NULLCRYPT=1
fi
PRE=""
if [ "$NULLCRYPT" = 0 ]; then
	printf 'char* crypt(const char*k,const char*s){(void)k;(void)s;return 0;}\n' > "$T/shim.c"
	if ${CC:-cc} -shared -fPIC -o "$T/shim.so" "$T/shim.c" 2>/dev/null; then
		PRE="LD_PRELOAD=$T/shim.so"; echo "  crypt() は NULL を返さない箱。shim で代役"
	else echo "  crypt() は NULL を返さず shim も作れない。skip"; fi
else echo "  crypt() は未知 salt に NULL を返す箱"; fi
if [ "$NULLCRYPT" = 1 ] || [ -n "$PRE" ]; then
	serve p2 "$BIN" "$PRE"
	{ [ "$alive_p2" = 1 ] && [ "$code_p2" = 401 ]; } && echo "  patched: 生きて 401" || { echo "  !! patched が 401 で生きない (code=$code_p2 alive=$alive_p2)"; rc=1; }
	if sbuild stock2 no ""; then
		serve s2 "$T/stock2/thttpd" "$PRE"
		[ "$alive_s2" = 0 ] && echo "  stock: 落ちた (再現)" || { echo "  !! stock が落ちない"; rc=1; }
	fi
fi

########################################################################
# CVE-2007-0158: expand_symlinks underflow (空 symlink + ASan)
echo "########## CVE-2007-0158 (underflow) on $OS ##########"
if ! ln -s "" "$T/et" 2>/dev/null; then
	rm -f "$T/et"; echo "  空 symlink を作れない箱。live テストは skip"
elif ! echo 'int main(){return 0;}' | ${CC:-cc} -fsanitize=address -x c - -o "$T/at" 2>/dev/null || ! "$T/at" 2>/dev/null; then
	rm -f "$T/et" "$T/at"; echo "  ASan が使えない箱 (未対応か ASLR)。live テストは skip"
else
	rm -f "$T/et" "$T/at"
	if sbuild sa yes "-fsanitize=address -g -O0" && sbuild na no "-fsanitize=address -g -O0"; then
		for lbl in na sa; do
			D="$T/u-$lbl"; rm -rf "$D"; mkdir -p "$D"; echo hi > "$D/real"; ln -s "" "$D/empty"
			ASAN_OPTIONS=abort_on_error=0:exitcode=99:detect_leaks=0 "$T/$lbl/thttpd" \
			    -p 18092 -d "$D" -l "$D/log" -i "$D/pid" -D -nos > "$D/out" 2>&1 &
			sleep 1
			curl -s -o /dev/null "http://127.0.0.1:18092/empty" 2>/dev/null || true
			sleep 0.6
			if grep -qi 'AddressSanitizer\|stack-buffer-underflow' "$D/out"; then f=1; else f=0; fi
			kill "$(cat "$D/pid" 2>/dev/null)" 2>/dev/null || true
			eval "asan_$lbl=$f"
		done
		[ "${asan_na:-0}" = 1 ] && echo "  stock: 空 symlink の要求で ASan が underflow を報告 (再現)" || { echo "  !! stock で ASan が出ない"; rc=1; }
		[ "${asan_sa:-0}" = 0 ] && echo "  patched: ASan 無警告" || { echo "  !! patched でも ASan が出る"; rc=1; }
	else echo "  ASan build 不可。live テストは skip"; fi
fi

rm -rf "$T"
echo
[ $rc = 0 ] && echo "== thttpd: reproduced/fixed as far as this box allows ($OS $(uname -m))" || echo "== thttpd: FAILURES on $OS"
exit $rc
