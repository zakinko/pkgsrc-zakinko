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
# ld.so.hints を壊すのは OpenBSD の ldconfig だけ。他の OS では見ない。
if [ "$(uname -s)" = OpenBSD ]; then
	# 上流 (ncurses の CF_LD_SEARCHPATH) へ「ldconfig -v ではなく -r を
	# 使えばよい」と言えるか。-r は hints を読むだけで書き直さない。
	echo "  ldconfig -r から取れる path: $(ldconfig -r | sed -n 's/.*search directories: //p')"
	_before=$(ldconfig -r | sed -n 's/.*search directories: //p')
	ldconfig -r > /dev/null 2>&1
	_after=$(ldconfig -r | sed -n 's/.*search directories: //p')
	[ "$_before" = "$_after" ] && echo "  ok ldconfig -r は hints を書き換えない" ||
		{ echo "!! ldconfig -r でも hints が変わった"; rc=1; }
	_hints=$(ldconfig -r 2>/dev/null | sed -n 's/.*search directories: //p')
	echo "  ld.so.hints: $_hints"
	case "$_hints" in */usr/local/lib*) : ;; *) echo "!! ld.so.hints から /usr/local/lib が消えた"; rc=1 ;; esac
fi
# 当て物は全 platform に当たるので、OpenBSD 以外で target が変わっていない
# ことも見る。ここが変わると他の OS の openssl を壊したことになる。
_t=$(grep -m1 'for target' "$T/openssl-install.log" | sed 's/.*for target //')
echo "  configure target: ${_t:-(log に無い)}"
case "$(uname -s)-$_t" in
OpenBSD-BSD-nodef-*)	;;
OpenBSD-*)		echo "!! OpenBSD で nodef でない target を選んだ"; rc=1 ;;
*-BSD-nodef-aarch64)	echo "!! OpenBSD 以外で BSD-nodef-aarch64 を選んだ"; rc=1 ;;
esac
echo "########## pkglint ##########"
sh "$(dirname "$0")/pkglint-check.sh" "$PKG" || rc=1

[ $rc -eq 0 ] && echo "RESULT: openssl は建つ" || echo "RESULT: 通らなかったものがある (上を読む)"
exit $rc
