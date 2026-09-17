#!/bin/sh
# security/openssl が OpenBSD で建つかと、engines/*.so の link に何が
# 渡っているかを見る。OpenBSD/arm64 (手元の HVF 箱) では
#
#	cc ... -Wl,-z,defs -shared ... -o engines/dasync.so ... -lcrypto -pthread
#	ld: error: undefined symbol: strcmp / memcpy / write / read / pipe / close
#
# で落ちた。DSO に -lc が無く、-z defs がそれを咎める。amd64 の CI では同じ
# package が通っているので、何が違うのかを両方で同じ形で出して比べる。
PKG=${1:-security/openssl}
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin; export PATH
T=${TMPDIR:-/tmp}
BMAKE=$PREFIX/bin/bmake
cd "$TREE/$PKG" || { echo "FAIL: $TREE/$PKG が無い"; exit 1; }
rc=0
echo "--- $PKG ($(uname -s) $(uname -r) / $(uname -m)) ---"
cc -v 2>&1 | grep -E 'version|Target' | sed 's/^/  /'
ld.lld --version 2>&1 | head -1 | sed 's/^/  /'

echo "########## 1. -shared -z defs の素の挙動 ##########"
printf '#include <string.h>\n#include <unistd.h>\nint f(char*a,char*b){ write(1,a,1); return strcmp(a,b);}\n' > "$T/zdefs.c"
cc -fPIC -c "$T/zdefs.c" -o "$T/zdefs.o"
for extra in "" "-pthread" "-lc"; do
	if cc -shared -Wl,-z,defs -o "$T/zdefs.so" "$T/zdefs.o" $extra > "$T/zdefs.log" 2>&1; then
		echo "  ok   cc -shared -Wl,-z,defs $extra"
	else
		echo "  fail cc -shared -Wl,-z,defs $extra : $(grep -m1 'undefined symbol' "$T/zdefs.log")"
	fi
done
nm -D /usr/lib/libpthread.so.* 2>/dev/null | grep -w -E 'write|read' | sed 's/^/  libpthread: /' | head -4

echo "########## 2. openssl を建てる ##########"
WRK=$($BMAKE show-var VARNAME=WRKDIR)
if $BMAKE install > "$T/openssl-install.log" 2>&1; then
	echo "  ok install"
else
	echo "!! install が落ちた"; rc=1
	_first=$(grep -n '\*\*\* Error code' "$T/openssl-install.log" | head -1 | cut -d: -f1)
	[ -n "$_first" ] && sed -n "$((_first > 30 ? _first - 30 : 1)),${_first}p" "$T/openssl-install.log" | cut -c1-200 | sed 's/^/     /'
fi
echo "  -- dasync.so の link (wrapper の前と後)"
grep -n 'dasync\.so' "$WRK/.work.log" 2>/dev/null | head -2 | cut -c1-500 | sed 's/^/     /'
grep -n -i 'dasync' "$T/openssl-install.log" | grep -v '^.*\.o' | head -3 | cut -c1-200 | sed 's/^/     /'
[ $rc -eq 0 ] && echo "RESULT: openssl は建つ" || echo "RESULT: 通らなかったものがある (上を読む)"
exit $rc
