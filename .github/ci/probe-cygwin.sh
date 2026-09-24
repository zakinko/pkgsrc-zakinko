#!/bin/sh
# Cygwin で pkgsrc の bootstrap がどこまで行くかを測るだけの偵察。
#
# 測る理由。go-bin の platform.mk に windows の archive を入れるかどうかを、
# 「pkgsrc は Windows で走らない」で決めようとしていた。それは誤りで、
# mk/platform/Cygwin.mk は在り、bootstrap にも CYGWIN_*) の場合分けが在る。
# 在るからといって bootstrap が通るとは限らないので、実機で測る。
#
# 知りたいのは三つだけ。
#   bootstrap が通るか
#   通ったら MACHINE_PLATFORM が何と綴られるか (表に書く左辺)
#   上流の windows archive がその platform に対応するか (go は cygwin を
#   target に持たないので、在るとすれば windows-* しかない)
#
# 何も決めつけない。失敗しても job は落とさない。
set +e

say() { echo; echo "########## $* ##########"; }

say "この箱は何か"
for c in 'uname -a' 'uname -o' 'uname -m' 'uname -s'; do
	printf '  %-12s ' "$c"; eval "$c" 2>&1 | head -1
done
echo "  SHELL=$SHELL  PATH=$PATH"

say "道具が在るか"
for t in sh bash ksh gcc cc make bmake sed awk gawk tar gzip xz curl wget git patch id; do
	p=$(command -v "$t" 2>/dev/null)
	[ -n "$p" ] && printf '  %-8s %s\n' "$t" "$p"
done

say "pkgsrc を取ってくる"
W=${TMPDIR:-/tmp}/cygp
rm -rf "$W"; mkdir -p "$W" || exit 0
cd "$W" || exit 0
n=0
while [ $n -lt 3 ]; do
	n=$((n + 1))
	curl -fsSL -o pkgsrc.tar.gz http://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz && break
	echo "  取得が失敗した ($n 回目)"; rm -f pkgsrc.tar.gz; sleep 5
done
[ -f pkgsrc.tar.gz ] || { echo "  取れなかった。ここで終わり"; exit 0; }
echo "  $(wc -c < pkgsrc.tar.gz) byte"
tar xzf pkgsrc.tar.gz || { echo "  展開できない"; exit 0; }
[ -d pkgsrc ] || { echo "  pkgsrc が無い"; exit 0; }

say "bootstrap を撃つ"
cd pkgsrc/bootstrap || exit 0
# unprivileged で。Administrators かどうかに依らせない。
./bootstrap --unprivileged --workdir "$W/wrk" --prefix "$W/pkg" \
	> "$W/bootstrap.log" 2>&1
rc=$?
echo "  rc=$rc"
if [ $rc -ne 0 ]; then
	echo "  --- log の末尾"
	tail -40 "$W/bootstrap.log" | sed 's/^/    /'
	echo "  --- error らしい行"
	grep -inE 'error|cannot|not found|no such|fail' "$W/bootstrap.log" |
		tail -15 | sed 's/^/    /'
	exit 0
fi

say "pkgsrc がこの箱をどう綴るか"
BM="$W/pkg/bin/bmake"
[ -x "$BM" ] || { echo "  bmake が無い: $BM"; exit 0; }
cd "$W/pkgsrc/pkgtools/pkg_install" 2>/dev/null || cd "$W/pkgsrc/lang/go-bin" 2>/dev/null || exit 0
for v in OPSYS OS_VERSION MACHINE_ARCH MACHINE_PLATFORM OBJECT_FMT; do
	printf '  %-18s %s\n' "$v" "$("$BM" show-var VARNAME=$v 2>/dev/null)"
done

say "読み方"
echo "  bootstrap が通って MACHINE_PLATFORM が読めたなら、それが表の左辺。"
echo "  go は cygwin を target に持たないので、右辺に入れられるのは"
echo "  windows-386 / windows-amd64 / windows-arm64 のいずれか。"
echo "  それが Cygwin の下で使える形かは、入れてから別に測る。"
