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
# NetBSD は base の make が bmake なので、/usr/pkg に bootstrap が無い箱でも
# 建てられる。決め打ちにしていたせいで、qemu の NetBSD 11.0 が
# "/usr/pkg/bin/bmake: not found" だけで落ち、pkgsrc の本拠地が openssl に
# ついて一度も測れていなかった。zlib も pkgconf も croc も fallback を持つ。
BMAKE=$PREFIX/bin/bmake; [ -x "$BMAKE" ] || BMAKE=make
cd "$TREE/$PKG" || { echo "FAIL: $TREE/$PKG が無い"; exit 1; }
rc=0
echo "--- $PKG ($(uname -s) $(uname -r) / $(uname -m)) ---"
cc -v 2>&1 | grep -E 'version|Target' | sed 's/^/  /'
# linker は cc に訊く。ld.lld 決め打ちだと NetBSD で "not found" が出て、
# 何か壊れているように見える (実際は GNU ld が使われている)。版の訊き方も
# 揃っていない — GNU と lld は --version、Apple の ld は -v。
_ld=$(cc -print-prog-name=ld 2>/dev/null)
if [ -x "${_ld:-}" ]; then
	_lv=$("$_ld" --version 2>/dev/null | head -1)
	[ -n "$_lv" ] || _lv=$("$_ld" -v 2>&1 | head -1)
	echo "  ld: ${_ld}${_lv:+  $_lv}"
else
	echo "  ld: (cc から引けず)"
fi

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
# 建っただけでは動く証拠にならない。入れた binary を走らせる。
# croc で croc-web を入れただけにしていたら、起動すらしない物を配って
# いたのが分かった。
echo "########## 入れた openssl を走らせる ##########"
if [ -x "$PREFIX/bin/openssl" ]; then
	_v=$("$PREFIX/bin/openssl" version 2>&1 | head -1)
	case "$_v" in
	OpenSSL*)	echo "  ok $_v" ;;
	*)		echo "!! openssl version が名乗らない: $_v"; rc=1 ;;
	esac
	# 実際に暗号を回す。名乗るだけなら version の table を読んだだけで通る。
	# 値は手元で shasum -a 256 と openssl dgst の両方から取った。
	_want=e04ac068955c93d64bcfe27eaa409d43ff8242e0ae8c4613292cfe282764627f
	_got=$(printf 'pkgsrc' | "$PREFIX/bin/openssl" dgst -sha256 2>&1 | sed 's/.*= *//')
	if [ "$_got" = "$_want" ]; then
		echo "  ok sha256('pkgsrc') が既知の値と合う"
	else
		echo "!! sha256('pkgsrc') が合わない: $_got"; rc=1
	fi
	# 共有 library が全部解決しているか (nodef の当て物は link を変える)
	if ldd "$PREFIX/bin/openssl" 2>/dev/null | grep -q 'not found'; then
		echo "!! 解決していない library が在る"
		ldd "$PREFIX/bin/openssl" | grep 'not found' | sed 's/^/     /'; rc=1
	fi
else
	echo "  ($PREFIX/bin/openssl が無い。入れていない回)"
fi

echo "########## pkglint ##########"
sh "$(dirname "$0")/pkglint-check.sh" "$PKG" || rc=1

[ $rc -eq 0 ] && echo "RESULT: openssl は建って動く" || echo "RESULT: 通らなかったものがある (上を読む)"
exit $rc
