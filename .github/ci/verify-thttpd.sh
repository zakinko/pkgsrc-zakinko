#!/bin/sh
# zakinko/thttpd を pkgsrc で建てて入れ、CVE を踏めるだけ踏む。
# build-on-bsd.sh が pkgsrc を bootstrap した後 PKGS='thttpd' で呼ぶ。
#
# 見るもの:
#   pkgsrc で建って入る
#   CVE-2009-4491 (log injection)  どの箱でも。上流に修正が無いので手厚く
#   CVE-2012-5640 (crypt NULL)     NULL を返す箱は native、返さない箱は shim
#   CVE-2007-0158 (underflow)      ASan の下で二つの入口を撃つ。長さ 0 の
#                                  symlink と、NUL で始まる .htpasswd の行
#
# どの CVE も素の 2.29 との対照を取る。素がそのまま建たない箱では
# patch-configure だけを当てて建て直す (2002 年の configure は試験
# program の main() に戻り値の型が無く、C99 を通さない compiler で
# 止まる)。この当て物は thttpd の code を一行も変えないので、対照と
# しての素の振舞いは保たれる。どちらで建てたかは出力に出す。
#
# pkgsrc の build 自体が箱の都合で落ちることもある。その場合も検査は
# 落とさず、同じ当て物を上流 tarball に当てて建て直して続ける。
set -e
# DragonFly の tar が locale を立てられずに落ちる。ESC を grep で探す
# 場所もあるので、byte で扱う C に寄せる。
LC_ALL=C; export LC_ALL
OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin:/usr/local/bin
export PATH
unset PKG_PATH
rc=0
T=${TMPDIR:-/tmp}/thttpd-v.$$; mkdir -p "$T"
DIR=$TREE/zakinko/thttpd
# pkgsrc で建てた bmake を先に見る。PATH は /usr/bin が $PREFIX/bin より
# 先なので、base にも bmake が在る箱 (FreeBSD) ではそちらが拾われる。
# base の bmake の既定 sys path は /usr/share/mk で、FreeBSD の
# bsd.own.mk は OBJECT_FMT を定義しない。すると bsd.prefs.mk の
#   NATIVE_OBJECT_FMT:= ${OBJECT_FMT}
# が未定義の参照をそのまま残し、次の行の定義と噛み合って
#   Variable OBJECT_FMT is recursive
# になる。pkgsrc の木を読ませるなら pkgsrc の bmake でなければならない。
if [ -x "$PREFIX/bin/bmake" ]; then PKGMAKE="$PREFIX/bin/bmake"
elif [ "$OS" = NetBSD ]; then PKGMAKE=make
else PKGMAKE=bmake; fi
echo "使う make: $PKGMAKE"

# 取得の道具は箱によって違う。NetBSD と OpenBSD には curl も wget も無く、
# base の ftp(1) が URL を取れる。
fetch_to() { # $1=url $2=outfile
	if command -v curl >/dev/null 2>&1; then curl -sSL -o "$2" "$1"
	elif command -v wget >/dev/null 2>&1; then wget -q -O "$2" "$1"
	elif command -v fetch >/dev/null 2>&1; then fetch -q -o "$2" "$1"
	elif command -v ftp >/dev/null 2>&1; then ftp -o "$2" "$1"
	else echo "!! 取得の道具が無い" >&2; return 1; fi
}
# HTTP 要求も同じ事情。応答の status だけ欲しいので、無ければ自前で喋る。
http_code() { # $1=url  [$2.. = extra headers "Name: value"]
	if command -v curl >/dev/null 2>&1; then
		_h=""
		for _x in "$2" "$3"; do [ -n "$_x" ] && _h="$_h -H \"$_x\""; done
		eval curl -s -o /dev/null -w \'%{http_code}\' $_h ${4:+-u "$4"} --max-time 5 "$1" 2>/dev/null || echo none
	else
		_hp=${1#http://}; _host=${_hp%%/*}; _path=/${_hp#*/}
		_ip=${_host%%:*}; _port=${_host##*:}
		{ printf 'GET %s HTTP/1.0\r\n' "$_path"
		  [ -n "$2" ] && printf '%s\r\n' "$2"
		  [ -n "$3" ] && printf '%s\r\n' "$3"
		  [ -n "$4" ] && printf 'Authorization: Basic %s\r\n' "$(printf '%s' "$4" | openssl base64 2>/dev/null | tr -d '\n')"
		  printf '\r\n'
		} | nc -w 5 "$_ip" "$_port" 2>/dev/null | sed -n '1s#^HTTP/[0-9.]* \([0-9][0-9][0-9]\).*#\1#p' | head -1
	fi
}
# OmniOS には cc(1) が無く、gcc だけが入っている。cc を決め打ちすると
# 探り program も shim も黙って建たず、踏めるはずの CVE が skip になる。
CC=${CC:-cc}
command -v "$CC" >/dev/null 2>&1 || CC=gcc
export CC

# pkgsrc の Makefile が OPSYS ごとに足している定義。tarball から建てる側と
# 探り program にも同じ物が要る (Linux の sigset、illumos の crypt)。
case $OS in
Linux)	OSCFLAGS=-D_GNU_SOURCE ;;
SunOS)	OSCFLAGS=-D__EXTENSIONS__ ;;
*)	OSCFLAGS= ;;
esac
sbuild() { # $1=label $2=applyPatch(yes/no) $3=CCflags -> $T/$1/thttpd
	rm -rf "$T/$1"
	# acme.com は落ちていることがある (一度 Operation timed out で job ごと
	# 落ちた)。pkgsrc が既に取っている物があればそれを使い、無ければ
	# acme.com、それでも駄目なら pkgsrc の配布物 mirror を当たる。
	if [ ! -f "$T/thttpd-2.29.tar.gz" ]; then
		D=$($PKGMAKE -C "$DIR" -V DISTDIR 2>/dev/null || echo "")
		if [ -n "$D" ] && [ -f "$D/thttpd-2.29/thttpd-2.29.tar.gz" ]; then
			cp "$D/thttpd-2.29/thttpd-2.29.tar.gz" "$T/thttpd-2.29.tar.gz"
		else
			for u in https://www.acme.com/software/thttpd/thttpd-2.29.tar.gz \
			         http://ftp.NetBSD.org/pub/pkgsrc/distfiles/thttpd-2.29/thttpd-2.29.tar.gz; do
				fetch_to "$u" "$T/thttpd-2.29.tar.gz" && break
				rm -f "$T/thttpd-2.29.tar.gz"
			done
		fi
	fi
	[ -s "$T/thttpd-2.29.tar.gz" ] || { echo "  !! 2.29 の tarball を取れない" >&2; return 1; }
	( cd "$T" && gzip -dc thttpd-2.29.tar.gz | tar xf - && mv thttpd-2.29 "$1" )
	case $2 in
	no)	;;
	conf)	# 2002 年の configure は試験 program の main() に戻り値の型が
		# 無く、C99 を通さない compiler では "C compiler cannot create
		# executables" で止まる。この当て物はそこだけを直し、thttpd の
		# code は一行も変えないので、対照としての素の振舞いは保たれる。
		( cd "$T/$1" && patch -s -p0 -f -i "$DIR/patches/patch-configure" \
		    >/dev/null 2>&1 </dev/null ) ;;
	*)	# 一覧を書き下すと当て物を足したときに古びる。patch-ag を
		# patch-CVE-2005-3124 に改名したとき、この一覧から漏れて
		# tarball 側の syslogtocern が素のままになっていた。
		for pp in "$DIR"/patches/patch-*; do
			[ -f "$pp" ] || continue
			( cd "$T/$1" && patch -s -p0 -f -i "$pp" \
			    >/dev/null 2>&1 </dev/null ) \
			    || { echo "  !! ${pp##*/} が $1 に当たらない" >&2; return 1; }
		done ;;
	esac
	( cd "$T/$1" && ./configure >/dev/null 2>&1 && make CC="$CC $OSCFLAGS $3" thttpd >bl.log 2>&1 )
	test -x "$T/$1/thttpd"
}

########################################################################
echo "########## build+install via pkgsrc ##########"
PKGSRC_OK=1
( cd "$DIR" && $PKGMAKE install ) || PKGSRC_OK=0
BIN=$PREFIX/sbin/thttpd
[ -x "$BIN" ] || BIN=$PREFIX/bin/thttpd
if [ "$PKGSRC_OK" = 1 ] && [ -x "$BIN" ]; then
	echo "MODE: pkgsrc で建てた $BIN を検査する"
else
	echo "!! pkgsrc build/install がこの箱では通らない。当て物入りを tarball から建てて検査を続ける"
	# FreeBSD で "Variable OBJECT_FMT is recursive" が出続けている。
	# 木の側の話で当て物とは関係ないが、原因を突き止めるまで隠れるので
	# 判断の材料をここで出す。
	echo "  診断: env の OBJECT_FMT 系"; env | grep -i object_fmt | sed 's/^/    /' || echo "    (無し)"
	# 再帰は makefile を読む途中で起きるので、bmake には何も訊けない
	# (-V も -v も同じ error を返す)。file の方を読む。
	echo "  診断: 見つかる bsd.own.mk と、その OBJECT_FMT"
	for f in /usr/share/mk/bsd.own.mk \
	         "$(dirname "$TREE")"/bootstrap-work/share/mk/bsd.own.mk \
	         /pkgsrc-ci/bootstrap-work/share/mk/bsd.own.mk \
	         "$PREFIX"/share/mk/bsd.own.mk; do
		[ -f "$f" ] || continue
		echo "    $f"
		grep -n 'OBJECT_FMT' "$f" | sed 's/^/      /' | head -4
	done
	echo "  診断: bsd.prefs.mk が OBJECT_FMT をどう定義しているか"
	grep -n 'OBJECT_FMT' "$TREE/mk/bsd.prefs.mk" | sed 's/^/    /' | head -12
	# bsd.prefs.mk を通らない小さな makefile で訊く。再帰はそこで起きる
	# ので、通さなければ bmake は普通に答えられる。
	# 目標を書くと "no target to make" になるので -V だけで訊く。
	echo "  診断: <bsd.own.mk> はどこから来て、OBJECT_FMT を定義するか"
	echo '.include <bsd.own.mk>' > "$T/own.mk"
	printf '    OBJECT_FMT=['; ( cd "$T" && $PKGMAKE -f own.mk -V OBJECT_FMT ) 2>&1 | head -1 | tr -d '\n'; echo ']'
	( cd "$T" && $PKGMAKE -f own.mk -V .MAKE.MAKEFILES ) 2>&1 | tr ' ' '\n' \
	    | grep 'own\.mk' | sed 's/^/    read: /' | head -3
	echo "    MAKESYSPATH=[${MAKESYSPATH:-未設定}]"
	sbuild patchedbin yes "" || { echo "!! tarball build も失敗"; exit 1; }
	BIN=$T/patchedbin/thttpd
	echo "MODE: tarball + pkgsrc patch の $BIN を検査する"
fi

serve() { # $1=label $2=binary $3=preload -> code_ alive_ log_
	D="$T/d-$1"; rm -rf "$D"; mkdir -p "$D/priv"
	echo hi > "$D/index.html"; echo secret > "$D/priv/index.html"
	printf 'bob:$9$notasalt\n' > "$D/priv/.htpasswd"
	env $3 "$2" -p 18091 -d "$D" -l "$D/log" -i "$D/pid" -D -nos > "$D/out" 2>&1 &
	sleep 1
	http_code "http://127.0.0.1:18091/x" \
	    "Referer: $(printf 'R\033]0;X\007')" "User-Agent: $(printf 'U\033[2J')" >/dev/null 2>&1 || true
	code=$(http_code "http://127.0.0.1:18091/priv/" "" "" "bob:pw" 2>/dev/null)
	[ -n "$code" ] || code=none
	sleep 0.4
	if kill -0 "$(cat "$D/pid" 2>/dev/null)" 2>/dev/null; then alive=1; else alive=0; fi
	kill "$(cat "$D/pid" 2>/dev/null)" 2>/dev/null || true
	eval "code_$1=$code alive_$1=$alive log_$1=$D/log"
}

# 素の 2.29 を建てる。そのまま建たない箱では configure だけを直して
# 建て直す。対照が取れないまま「この箱では測れない」で済ませると、
# 当て物が効いているかを言えるのが一部の箱だけになる。
STOCKMODE=""
stockbuild() { # $1=label $2=CCflags
	if sbuild "$1" no "$2"; then STOCKMODE="素のまま"; return 0; fi
	if sbuild "$1" conf "$2"; then
		STOCKMODE="patch-configure のみ (thttpd の code は無変更)"; return 0
	fi
	STOCKMODE=""
	# 落ちた理由を捨てない。「対照は略」とだけ出して先へ進むと、
	# 測れていないことの原因が残らない。
	for f in "$T/$1/bl.log" "$T/$1/config.log"; do
		[ -f "$f" ] && { echo "  $1 の ${f##*/} 末尾:"; \
		    tail -8 "$f" | sed 's/^/    /'; }
	done
	return 1
}

########################################################################
echo "########## CVE-2009-4491 (log injection) on $OS ##########"
serve patched "$BIN" ""
if grep -q "$(printf '\033')" "$log_patched" 2>/dev/null; then echo "  !! patched log に生の ESC"; rc=1
else echo "  patched: 生の ESC なし"; fi
if grep -q '\\x1b' "$log_patched" 2>/dev/null; then echo "  patched: \\x1b に escape されている"
else echo "  !! patched log に \\x1b が無い"; rc=1; fi
if stockbuild stock ""; then
	echo "  対照の素は $STOCKMODE で建てた"
	serve stock "$T/stock/thttpd" ""
	if grep -q "$(printf '\033')" "$log_stock" 2>/dev/null; then echo "  stock: 生の ESC が log に入る (再現)"
	else echo "  !! stock で ESC が再現しない"; rc=1; fi
else echo "  (素の 2.29 を建てられず、対照は略)"; fi

########################################################################
echo "########## CVE-2012-5640 (crypt NULL) on $OS ##########"
cat > "$T/cr.c" <<'C'
#include <stdio.h>
#include <unistd.h>
#if defined(__linux__)
#include <crypt.h>
#endif
int main(void){char*r=crypt("pw","$9$notasalt");printf("%s\n",r?r:"NULL");return r?1:0;}
C
# cr は crypt() が値を返したら 1、NULL なら 0 で終わる。NULL を返す箱を
# 探しているので、真を取るのは exit 0 の側。ここを || にしていたため
# NetBSD と FreeBSD ("*0" を返す箱) に「NULL を返す」印が立ち、
# 落ちない stock を失敗として数えていた。
NULLCRYPT=0
if $CC $OSCFLAGS -o "$T/cr" "$T/cr.c" -lcrypt 2>/dev/null \
   || $CC $OSCFLAGS -o "$T/cr" "$T/cr.c" 2>/dev/null; then
	"$T/cr" >/dev/null 2>&1 && NULLCRYPT=1
fi
PRE=""
if [ "$NULLCRYPT" = 0 ]; then
	printf 'char* crypt(const char*k,const char*s){(void)k;(void)s;return 0;}\n' > "$T/shim.c"
	if $CC $OSCFLAGS -shared -fPIC -o "$T/shim.so" "$T/shim.c" > "$T/shim.err" 2>&1; then
		PRE="LD_PRELOAD=$T/shim.so"; echo "  crypt() は NULL を返さない箱。shim で代役"
	else
		echo "  crypt() は NULL を返さず shim も作れない。skip"
		sed 's/^/    /' "$T/shim.err"
	fi
else echo "  crypt() は未知 salt に NULL を返す箱"; fi
if [ "$NULLCRYPT" = 1 ] || [ -n "$PRE" ]; then
	serve p2 "$BIN" "$PRE"
	{ [ "$alive_p2" = 1 ] && [ "$code_p2" = 401 ]; } && echo "  patched: 生きて 401" || { echo "  !! patched が 401 で生きない (code=$code_p2 alive=$alive_p2)"; rc=1; }
	if [ -x "$T/stock/thttpd" ]; then
		serve s2 "$T/stock/thttpd" "$PRE"
		if [ "$alive_s2" = 0 ]; then
			echo "  stock: 落ちた (再現)"
		elif [ "$NULLCRYPT" = 1 ]; then
			echo "  !! crypt() が NULL を返す箱なのに stock が落ちない"; rc=1
		else
			# crypt() が NULL を返さない箱。shim を被せても、thttpd が
			# 静的に link されていたり LD_PRELOAD を見ない箱では刺さらない。
			# 踏めないだけで、当て物が効いていないわけではない。
			echo "  stock: 落ちない (この箱の crypt() は NULL を返さず、shim も効かない)"
		fi
	fi
fi

########################################################################
echo "########## CVE-2007-0158 (underflow) on $OS ##########"
# ASan が動くか。NetBSD は ASLR と shadow の置き場が衝突して起動すらしない
# ので、binary ごとに外せるなら外して測る。測れない理由が箱の設定なら、
# その設定の方を外す。
asan_works() {
	echo 'int main(){return 0;}' | $CC -fsanitize=address -x c - -o "$T/at" 2>/dev/null \
	    || { echo "  この箱の $CC は -fsanitize=address を持たない"; return 1; }
	"$T/at" 2>/dev/null && return 0
	# paxctl(8) は小文字が「明示的に無効化」で、大文字は有効化。ASLR を
	# 切るのは +a であって -A ではない (-A は有効化の印を外すだけ)。
	if command -v paxctl >/dev/null 2>&1 && paxctl +a "$T/at" >/dev/null 2>&1 \
	   && "$T/at" 2>/dev/null; then
		echo "  ASLR が ASan を止めていた。paxctl +a で切って測る"
		return 0
	fi
	echo "  ASan を建てられても走らせられない"
	return 1
}

_asan_run() { # $1=dir $2=binary $3=path $4=auth
	ASAN_OPTIONS=abort_on_error=0:exitcode=99:detect_leaks=0 "$2" \
	    -p 18092 -d "$1" -l "$1/log" -i "$1/pid" -D -nos > "$1/out" 2>&1 &
	sleep 1
	http_code "http://127.0.0.1:18092$3" "" "" "$4" >/dev/null 2>&1 || true
	sleep 0.6
	kill "$(cat "$1/pid" 2>/dev/null)" 2>/dev/null || true
}

# 一つの入口を撃って、ASan が報告するかどうかを返す。
asan_probe() { # $1=dirlabel $2=binary $3=setup関数 $4=path [$5=auth]
	D="$T/u-$1"; rm -rf "$D"; mkdir -p "$D"
	"$3" "$D" || return 2
	_asan_run "$D" "$2" "$4" "${5:-}"
	# ASan の shadow は ASLR と場所を取り合うので、NetBSD では起動すら
	# しない。binary ごとに外せるなら外して撃ち直す。素の試験 program は
	# 動いてしまうので、ここまで来ないと分からない。
	if grep -q 'not compatible with enabled ASLR' "$D/out" 2>/dev/null; then
		if command -v paxctl >/dev/null 2>&1; then
			if paxctl +a "$2" >"$D/pax" 2>&1; then
				echo "    ASLR が ASan を止めていた。paxctl +a で切って撃ち直す"
				_asan_run "$D" "$2" "$4" "${5:-}"
			else
				echo "    paxctl +a が通らない:"; sed 's/^/      /' "$D/pax"
			fi
		else
			echo "    ASLR が ASan を止めているが paxctl が無い"
		fi
	fi
	# それでも駄目なら、この箱の PaX の効かせ方を出す。global が 1 の
	# ままだと binary ごとの印が届かないことがある。
	if grep -q 'not compatible with enabled ASLR' "$D/out" 2>/dev/null; then
		echo "    まだ ASLR で止まる。この箱の設定:"
		sysctl security.pax.aslr 2>&1 | sed 's/^/      /' | head -3
		command -v paxctl >/dev/null 2>&1 && \
		    { echo "      binary の PaX flag:"; paxctl "$2" 2>&1 | sed 's/^/        /'; }
	fi
	ASANOUT="$D/out"
	# BSD の grep は BRE の \| を解さないので、語を一つだけ渡す。
	grep -qi AddressSanitizer "$D/out"
}

# 判定の根拠を出す。出たときは報告の頭、出なかったときは何が起きたか。
show_asan() { # $1=見出し
	if [ -s "$ASANOUT" ]; then
		sed -n '1,6p' "$ASANOUT" | sed "s/^/    $1: /"
	else
		echo "    $1: 出力が空 (起動しなかった可能性)"
	fi
}

# 入口その一: 配信する木の中の長さ 0 の symlink -> expand_symlinks() の lnk[-1]
setup_symlink() {
	echo hi > "$1/real"
	ln -s "" "$1/empty" 2>/dev/null || return 1
}
# 入口その二: NUL で始まる .htpasswd の行 -> auth_check2() の line[-1]
# Linux は空の symlink を作れないので、同じ CVE をこちらから撃つ。
setup_nulauth() {
	mkdir -p "$1/priv"; echo secret > "$1/priv/index.html"
	printf '\000bob:x\n' > "$1/priv/.htpasswd"
	[ "$(wc -c < "$1/priv/.htpasswd" | tr -d ' ')" = 7 ] || return 1
}

if asan_works; then
	rm -f "$T/at"
	if sbuild sa yes "-fsanitize=address -g -O0" \
	   && stockbuild na "-fsanitize=address -g -O0"; then
		echo "  対照の素は $STOCKMODE で建てた"
		hit=0
		for probe in symlink nulauth; do
			case $probe in
			symlink) setup=setup_symlink; path=/empty;    auth="" ;;
			nulauth) setup=setup_nulauth; path=/priv/;    auth="bob:x" ;;
			esac
			# "if ! f" のあとの $? は否定した後の値なので、先に取る。
			# ただし裸で呼ぶと set -e が非零でそこで script を終わらせる
			# ので、|| で受けて status を拾う。
			st=0
			asan_probe "n-$probe" "$T/na/thttpd" "$setup" "$path" "$auth" || st=$?
			if [ "$st" != 0 ]; then
				if [ "$st" = 2 ]; then echo "  $probe: この箱では仕込めない。skip"
				else
					echo "  $probe: stock で ASan が出ない"
					show_asan stock
				fi
				continue
			fi
			hit=1
			echo "  $probe: stock で ASan が報告 (再現)"
			show_asan stock
			if asan_probe "p-$probe" "$T/sa/thttpd" "$setup" "$path" "$auth"; then
				echo "  !! $probe: patched でも ASan が出る"; rc=1
				show_asan patched
			else
				echo "  $probe: patched は無警告"
			fi
		done
		[ "$hit" = 1 ] || { echo "  !! どちらの入口でも stock が再現しない"; rc=1; }
	else
		echo "  ASan 付きで建てられない。live テストは skip"
		for d in sa na; do
			[ -f "$T/$d/bl.log" ] && { echo "    $d の build log 末尾:"; \
			    tail -8 "$T/$d/bl.log" | sed 's/^/      /'; }
			[ -f "$T/$d/config.log" ] && [ ! -f "$T/$d/bl.log" ] && { \
			    echo "    $d の configure 末尾:"; \
			    tail -8 "$T/$d/config.log" | sed 's/^/      /'; }
		done
	fi
else
	echo "  ASan が使えない箱。live テストは skip"
fi

########################################################################
# CVE-2005-3124 の当て物 (patch-ag) が本当に効いているか。入れた script が
# shell として読めるかどうかは、報告で「直した」と書く以上、機械で見る。
echo "########## patch-ag (syslogtocern) on $OS ##########"
# pkgsrc で入った物を優先し、tarball の代役で回っている箱では建てた木の
# 中の物を見る。入っていないから skip、では当て物を測れていない。
SC=$PREFIX/sbin/syslogtocern
[ -f "$SC" ] || SC=$PREFIX/bin/syslogtocern
[ -f "$SC" ] || SC=$T/patchedbin/extras/syslogtocern
[ -f "$SC" ] || SC=${BIN%/thttpd}/extras/syslogtocern
if [ -f "$SC" ]; then
	if sh -n "$SC" 2>"$T/sc.err"; then
		echo "  patched: 構文が通る"
	else
		echo "  !! patched の syslogtocern が構文で落ちる"; rc=1
		sed 's/^/    /' "$T/sc.err"
	fi
	# 素の syslog 行を食わせて、CERN 形式の二つが出来るかを見る。
	D="$T/sc"; rm -rf "$D"; mkdir -p "$D"
	printf 'Sep 22 03:00:00 h thttpd[1]: 10.0.0.1 - - "GET /x HTTP/1.0" 200 3 "" "" - - - - -\n' > "$D/m.log"
	printf 'Sep 22 03:00:01 h thttpd[1]: tried to retrieve an auth file\n' >> "$D/m.log"
	( cd "$D" && sh "$SC" m.log ) >"$D/out" 2>&1 || true
	if [ -s "$D/access_log" ] && [ -s "$D/error_log" ]; then
		echo "  patched: access_log と error_log を書いた"
		sed 's/^/    /' "$D/access_log" | head -1
	else
		echo "  !! patched が log を変換しない"; rc=1
		sed 's/^/    /' "$D/out" | head -4
	fi
	# 対照: backtick を一つ戻すと落ちる、を見せる。原因がその一文字で
	# あることを、言葉ではなく shell に言わせる。
	# この file には latin-1 の (c) が入っているので、UTF-8 の locale だと
	# sed が "illegal byte sequence" で何も出さない。空 file は構文が通って
	# しまうので、対照が黙って無効になる。LC_ALL=C は先頭で立ててあるが、
	# 置き換わったことも数えて確かめる。
	sed 's,tmp1=`mktemp,tmp1=``mktemp,' "$SC" > "$D/before"
	if [ "$(grep -c 'tmp1=``mktemp' "$D/before" 2>/dev/null)" != 1 ]; then
		echo "  !! 対照を作れない (sed が置き換えていない)"; rc=1
	elif sh -n "$D/before" 2>"$D/before.err"; then
		echo "  !! backtick を戻しても構文が通る。対照になっていない"; rc=1
	else
		echo "  対照: backtick を一つ戻すと落ちる"
		sed 's/^/    /' "$D/before.err" | head -2
	fi
else
	echo "  syslogtocern が入っていない箱。skip"
fi

########################################################################
# doc/pkg-vulnerabilities の上限を thttpd<2.29nb1 へ狭める変更が、本当に
# audit を黙らせるか。「直した」と書く以上、鳴り止むことも機械で見る。
echo "########## pkg-vulnerabilities on $OS ##########"
# bmake の -V は版によって展開しない生の値を返す (${DISTNAME}nb${PKGREVISION}
# がそのまま出た)。pkgsrc 自身の show-var は必ず展開する。
PKGN=$( ( cd "$DIR" && $PKGMAKE show-var VARNAME=PKGNAME ) 2>/dev/null | tail -1 )
# 引けなかったときは bmake の error 文がそのまま入る (FreeBSD は
# OBJECT_FMT の再帰でここまで来られない)。中身の形で弾く。
case $PKGN in
thttpd-[0-9]*) ;;
*)	echo "  PKGNAME を引けない ($PKGN)"; PKGN="" ;;
esac
if [ -z "$PKGN" ]; then
	echo "  この箱では pkgsrc から PKGNAME を引けないので skip。"
	echo "  audit の照合は箱に依らないので、他の箱の結果で足りる。"
else
	echo "  この package は $PKGN"
	# 本物を取ってきて、そこへ差分と同じ書き換えを当てる。合成した file で
	# 測ると、書き方が違っていても気づけない。pkg_admin は libarchive 越しに
	# 読むので **圧縮されていないと "Unrecognized archive format" で黙る**。
	# 配られている物は名前に .gz が付かないまま gzip されているので、
	# grep も sed もそのままでは静かに 0 件を返す。
	V="$T/vuln"; rm -rf "$V"; mkdir -p "$V/before" "$V/after"
	$PREFIX/sbin/pkg_admin -K "$V/before" fetch-pkg-vulnerabilities >/dev/null 2>&1 || true
	RAW="$V/before/pkg-vulnerabilities"
	if [ ! -s "$RAW" ]; then echo "  pkg-vulnerabilities を取れない。skip"
	else
		gzip -dc "$RAW" > "$V/plain" 2>/dev/null || cp "$RAW" "$V/plain"
		nl=$(grep -c '^thttpd' "$V/plain" || true)
		echo "  取ってきた file の thttpd 行: $nl"
		sed 's,^thttpd-\[0-9\]\*,thttpd<2.29nb1,' "$V/plain" > "$V/plain.after"
		nc=$(grep -c '^thttpd<2.29nb1' "$V/plain.after" || true)
		echo "  書き換わった行: $nc"
		gzip -c "$V/plain"       > "$V/before/pkg-vulnerabilities"
		gzip -c "$V/plain.after" > "$V/after/pkg-vulnerabilities"
		for mode in before after; do
			n=$($PREFIX/sbin/pkg_admin -K "$V/$mode" audit-pkg "$PKGN" 2>/dev/null | grep -c . || true)
			echo "  $mode: $n 件"
			eval "n_$mode=$n"
		done
	fi
	if [ "${n_before:-0}" -ge 3 ] && [ "${n_after:-1}" = 0 ]; then
		echo "  上限を狭めると鳴り止む"
	else
		echo "  !! 上限の効き方が期待どおりでない"; rc=1
	fi
fi

rm -rf "$T"
echo
[ $rc = 0 ] && echo "== thttpd: この箱で踏める範囲は再現・修正とも確認 ($OS $(uname -m))" || echo "== thttpd: FAILURES on $OS"
exit $rc
