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
# run-in-qemu.sh はゲストへ VERIFY_OPTS しか運ばないので、そこからも読む。
for _o in ${VERIFY_OPTS:-}; do
	case $_o in
	test)	OPENSSL_TEST=yes ;;
	nolint)	SKIP_PKGLINT=yes ;;
	esac
done
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
	# Configure が target を受け付けないと、文句の一行のあとに target の
	# 一覧が何百行も続き、上の末尾 30 行には文句が入らない。頭を出す。
	echo "  -- Configure の頭"
	grep -n -A6 'Configuring OpenSSL' "$T/openssl-install.log" | head -12 | cut -c1-200 | sed 's/^/     /'
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
# 64bit の箱で generic32 は、config の推測が外れて asm も 64bit の bn も
# 使わない形。NetBSD/riscv64 がこれで黙って通っていた。
case "$_t" in
*generic32*)
	if [ "$(getconf LONG_BIT 2>/dev/null)" = 64 ]; then
		echo "!! 64bit の箱で $_t を選んだ"; rc=1
	fi ;;
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
	# 暗号を時間で回す。speed は EVP の実装 (asm が在れば asm) を通る。
	if "$PREFIX/bin/openssl" speed -seconds 1 -evp aes-256-gcm > "$T/speed.log" 2>&1; then
		echo "  ok speed aes-256-gcm: $(tail -1 "$T/speed.log")"
	else
		echo "!! openssl speed が落ちた"; tail -5 "$T/speed.log"; rc=1
	fi
	# 共有 library が全部解決しているか (nodef の当て物は link を変える)
	if ldd "$PREFIX/bin/openssl" 2>/dev/null | grep -q 'not found'; then
		echo "!! 解決していない library が在る"
		ldd "$PREFIX/bin/openssl" | grep 'not found' | sed 's/^/     /'; rc=1
	fi
else
	echo "  ($PREFIX/bin/openssl が無い。入れていない回)"
fi

# 上流の試験。OPENSSL_TEST=yes のときだけ回す (openssl4.yml)。
#
# 04-test_bio_dgram.t は NetBSD 11.1/amd64 (techne) で recvmmsg の後に戻らず、
# 42 分止まった。全体に混ぜるとそこで job の時間切れまで待つので、外して
# 回し、それだけ別に時間を切って回す。結果はどちらも数で出す。
if [ "${OPENSSL_TEST:-}" = yes ]; then
	echo "########## make test (test_bio_dgram を除く) ##########"
	SRC=$($BMAKE show-var VARNAME=WRKSRC)
	GM=$(command -v gmake || command -v make)
	J=$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
	( cd "$SRC" && HARNESS_JOBS=$J "$GM" test TESTS=-test_bio_dgram ) \
		> "$T/openssl-test.log" 2>&1
	_trc=$?
	grep -E '^(Files=|Result:)' "$T/openssl-test.log" | sed 's/^/  /'
	grep -E '^[0-9]+-test_[a-z0-9_]+\.t +\(Wstat' "$T/openssl-test.log" | sed 's/^/  FAIL /'
	_ok=$(grep -c -E '\.\. ok' "$T/openssl-test.log")
	_sk=$(grep -c -E '\.\. skipped' "$T/openssl-test.log")
	echo "  ok の行 $_ok、skipped の行 $_sk、exit $_trc"
	if [ $_trc -ne 0 ]; then
		rc=1
		sed -n '/^Test Summary Report/,/^Result:/p' "$T/openssl-test.log" | head -40 | sed 's/^/     /'
		# 要約は番号しか言わない。落ちた試験を V=1 で回し直し、not ok の
		# 前後を出す (DragonFly の 02-test_errstr.t は 54 と 59 としか
		# 分からなかった)。
		for _f in $(grep -E '^[0-9]+-test_[a-z0-9_]+\.t +\(Wstat' "$T/openssl-test.log" |
		    sed 's/^[0-9]*-\(test_[a-z0-9_]*\)\.t.*/\1/' | sort -u); do
			echo "  -- $_f を V=1 で"
			( cd "$SRC" && "$GM" test TESTS=$_f V=1 ) 2>&1 |
				grep -B4 -A2 'not ok' | head -60 | cut -c1-200 | sed 's/^/     /'
		done
	fi
	echo "########## test_bio_dgram を 300 秒で切って回す ##########"
	( cd "$SRC" && "$GM" test TESTS=test_bio_dgram V=1 ) > "$T/openssl-dgram.log" 2>&1 &
	_dp=$!
	_n=0
	while kill -0 $_dp 2>/dev/null && [ $_n -lt 300 ]; do sleep 5; _n=$((_n + 5)); done
	if kill -0 $_dp 2>/dev/null; then
		echo "  HANG: 300 秒で戻らない (bio_dgram_test を止める)"
		pkill -f bio_dgram_test 2>/dev/null || true
		wait $_dp 2>/dev/null
		tail -12 "$T/openssl-dgram.log" | sed 's/^/     /'
	else
		wait $_dp; _drc=$?
		echo "  test_bio_dgram: exit $_drc ($_n 秒)"
		grep -E '^(Result:|not ok|ok )' "$T/openssl-dgram.log" | head -8 | sed 's/^/     /'
	fi
fi

# pkglint は Go で書かれていて、入っていない箱では lang/go から組む。
# 異 arch の TCG ではそれだけで何時間もかかるので、openssl4.yml は外す。
if [ "${SKIP_PKGLINT:-}" != yes ]; then
echo "########## pkglint ##########"
sh "$(dirname "$0")/pkglint-check.sh" "$PKG" || rc=1
fi

[ $rc -eq 0 ] && echo "RESULT: openssl は建って動く" || echo "RESULT: 通らなかったものがある (上を読む)"
exit $rc
