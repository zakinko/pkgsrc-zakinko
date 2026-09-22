#!/bin/sh
# devel/zlib が建ち、負の長さで crc32_combine64 が返るか。
#
#   sh verify-zlib.sh devel/zlib
#
# 当て物の前は同じ呼び出しが戻らない (CVE-2026-27171)。戻らないことを
# CI で測るわけにはいかないので、当てた後に「返る」ことだけを見る。
# 当てる前に固まることは手元の zlib-1.3.1 で見た (5 秒の CPU 上限で死ぬ)。
PKG=${1:-devel/zlib}
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin; export PATH
T=${TMPDIR:-/tmp}
BMAKE=$PREFIX/bin/bmake
[ -x "$BMAKE" ] || BMAKE=make
cd "$TREE/$PKG" || { echo "FAIL: $TREE/$PKG が無い"; exit 1; }
rc=0
echo "--- $PKG ($(uname -s) $(uname -r) / $(uname -m)) ---"
grep -n 'len2 < 0' files/crc32.c | sed 's/^/  /' || { echo "!! 当て物が入っていない"; rc=1; }

echo "########## 1. 建てて入れる ##########"
if $BMAKE install > "$T/zlib-install.log" 2>&1; then
	echo "  ok install"
else
	echo "!! install が落ちた"; rc=1
	_f=$(grep -n '\*\*\* Error code' "$T/zlib-install.log" | head -1 | cut -d: -f1)
	[ -n "$_f" ] && sed -n "$((_f > 30 ? _f - 30 : 1)),${_f}p" "$T/zlib-install.log" | cut -c1-180 | sed 's/^/     /'
fi

echo "########## 2. 負の長さで戻るか ##########"
cat > "$T/zt.c" <<'CEOF'
#include <stdio.h>
#include <stdint.h>
extern unsigned long crc32_combine64(unsigned long, unsigned long, int64_t);
extern unsigned long crc32_combine_gen64(int64_t);
int main(void) {
	printf("combine64(1,2,-1)=%lu\n", crc32_combine64(1, 2, (int64_t)-1));
	printf("combine_gen64(-1)=%lu\n", crc32_combine_gen64((int64_t)-1));
	printf("combine64(1,2,16)=%lu\n", crc32_combine64(1, 2, (int64_t)16));
	return 0;
}
CEOF
if cc -I"$PREFIX/include" -o "$T/zt" "$T/zt.c" -L"$PREFIX/lib" -lz > "$T/zt.log" 2>&1; then
	if ( ulimit -t 10; "$T/zt" ) > "$T/zt.out" 2>&1; then
		sed 's/^/  /' "$T/zt.out"
		grep -q 'combine64(1,2,-1)=0' "$T/zt.out" || { echo "!! 負の長さで 0 が返らない"; rc=1; }
		grep -q 'combine_gen64(-1)=0' "$T/zt.out" || { echo "!! gen の方が 0 を返さない"; rc=1; }
		grep -qE 'combine64\(1,2,16\)=[1-9]' "$T/zt.out" || { echo "!! 正の長さの答えが変わった"; rc=1; }
	else
		echo "!! 10 秒の CPU 上限で戻らなかった"; rc=1; cat "$T/zt.out" | sed 's/^/     /'
	fi
else
	echo "!! test の build が落ちた"; tail -5 "$T/zt.log" | sed 's/^/     /'; rc=1
fi

echo "########## 3. zlib 自身の test ##########"
_w=$($BMAKE show-var VARNAME=WRKSRC)
if [ -d "$_w" ] && ( cd "$_w" && make test > "$T/zlib-test.log" 2>&1 ); then
	grep -i 'test OK' "$T/zlib-test.log" | sed 's/^/  /'
else
	echo "  (zlib の make test は回せなかった。build は上で見ている)"
fi

[ $rc -eq 0 ] && echo "RESULT: zlib は建ち、負の長さで戻る" || echo "RESULT: 通らなかったものがある (上を読む)"
exit $rc
