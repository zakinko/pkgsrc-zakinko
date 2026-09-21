#!/bin/sh
# zakinko/thttpd の patch-libhttpd.c (CVE-2012-5640, CVE-2009-4491) を、
# 上流の tarball を素で建てた物と当て物入りとで同じ入力に掛ける。
#
#   sh verify-thttpd-cve.sh <patches dir>
#
# pkgsrc は使わない。configure && make thttpd だけ。
#
# 5640 の落ちる筋は crypt() が NULL を返す libc でしか踏めない。NetBSD も
# 今の Linux (libxcrypt) も "*0" を返す。illumos は NULL を返す。NULL を
# 返さない箱では、crypt を NULL にする shim を LD_PRELOAD して code path
# だけを撃ち、それを「代役」と印字する。
set -e
P=$(cd "$1" && pwd)
T=${TMPDIR:-/tmp}/thttpd-cve.$$; mkdir -p "$T"; cd "$T"
curl -sSLO https://www.acme.com/software/thttpd/thttpd-2.29.tar.gz
# illumos の tar は --strip-components を知らない。展開して改名する。
for v in stock patched; do
	gzip -dc thttpd-2.29.tar.gz | tar xf - && mv thttpd-2.29 $v
	test -f $v/configure
	if [ $v = patched ]; then (cd $v && patch -p0 -f < "$P/patch-libhttpd.c" >/dev/null); fi
	(cd $v && ./configure >/dev/null && make thttpd >/dev/null 2>&1)
	test -x $v/thttpd
done

# この libc の crypt() は未知の salt に何を返すか
cat > cr.c <<'C'
#include <stdio.h>
#include <unistd.h>
#ifdef __linux__
#include <crypt.h>
#endif
int main(void){char*r=crypt("pw","$9$notasalt");printf("crypt -> %s\n",r?r:"NULL");return r?1:0;}
C
cc -o cr cr.c -lcrypt 2>/dev/null || cc -o cr cr.c
if ./cr; then NULLCRYPT=1; else NULLCRYPT=0; fi

# NULL を返さない箱では shim で代役
PRELOAD=
if [ $NULLCRYPT = 0 ]; then
	printf 'char* crypt(const char* k, const char* s){ (void)k; (void)s; return 0; }\n' > shim.c
	cc -shared -fPIC -o shim.so shim.c
	PRELOAD="LD_PRELOAD=$T/shim.so"
	echo "crypt() は NULL を返さない箱。shim で NULL にして代役 ($PRELOAD)"
fi

run() {
	D=$T/t-$1; rm -rf $D; mkdir -p $D/www/priv
	echo hello > $D/www/index.html; echo secret > $D/www/priv/index.html
	printf 'bob:$9$notasalt\n' > $D/www/priv/.htpasswd
	env $PRELOAD $T/$1/thttpd -p 18080 -d $D/www -l $D/access.log -i $D/pid -D -nos > $D/out 2>&1 &
	sleep 1
	echo "== $1: escape in Referer/UA"
	curl -s -o /dev/null -w '%{http_code}\n' "http://127.0.0.1:18080/x" \
	    -H "Referer: $(printf '\033]0;REF\007')" -A "$(printf 'UA\033[2J')" || true
	echo "== $1: bad .htpasswd salt"
	code=$(curl -s -o /dev/null -w '%{http_code}' -u bob:pw http://127.0.0.1:18080/priv/ || echo none)
	echo "http=$code"
	sleep 0.5
	if kill -0 $(cat $D/pid 2>/dev/null) 2>/dev/null; then echo "$1: ALIVE"; alive=1; else echo "$1: DEAD"; alive=0; fi
	echo "== $1: access.log"; cat -v $D/access.log 2>/dev/null || true
	kill $(cat $D/pid) 2>/dev/null || true
	eval "alive_$1=$alive; code_$1=$code"
}
run stock
run patched

rc=0
[ "$alive_stock" = 0 ] || { echo "!! 素の 2.29 が落ちない (5640 が再現しない)"; rc=1; }
[ "$alive_patched" = 1 ] && [ "$code_patched" = 401 ] || { echo "!! 当て物入りが生きて 401 を返さない"; rc=1; }
grep -q "$(printf '\033')" t-stock/access.log || { echo "!! 素の log に生の ESC が無い (4491 が再現しない)"; rc=1; }
grep -q "$(printf '\033')" t-patched/access.log && { echo "!! 当て物入りの log に生の ESC"; rc=1; }
grep -q '\\x1b' t-patched/access.log || { echo "!! 当て物入りの log に \\x1b が無い"; rc=1; }
[ $rc = 0 ] && echo "== ok ($(uname -s) $(uname -m), crypt NULL=$NULLCRYPT)"
rm -rf "$T"
exit $rc
