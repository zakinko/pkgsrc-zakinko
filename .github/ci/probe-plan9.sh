#!/bin/sh
# Plan 9 で pkgsrc の bootstrap がどこまで行くかを測るだけの偵察。
# 直すのはその後。2013 年の staal1978 氏の試みは bmake を建てる所で
# 止まったと README に書いてあるが、それが今も同じかは誰も測っていない。
#
# 何も決めつけない。在る物を数えてから進む。失敗しても job は落とさない。
set +e

say() { echo; echo "########## $* ##########"; }

say "この箱は何か"
for c in 'uname -a' 'cat /dev/osversion' 'cat /dev/user' 'cat /dev/sysname'; do
	printf '  %-22s ' "$c"; eval "$c" 2>&1 | head -1
done
echo "  PATH: $PATH"
echo "  \$0  : $0"

say "道具が在るか"
for t in sh rc ape/psh ape/sh cc 6c 8c gcc make mk bmake sed awk gawk \
         tar gzip bzip2 hget curl wget git patch ar ld nm cpp id whoami env xargs; do
	p=$(command -v "$t" 2>/dev/null)
	[ -n "$p" ] && printf '  %-10s %s\n' "$t" "$p"
done
echo "  --- APE の下"
for d in /bin/ape /$objtype/bin/ape /rc/bin/ape; do
	[ -d "$d" ] && { echo "  $d:"; ls "$d" 2>/dev/null | tr '\n' ' ' | fold -w 100 | sed 's/^/    /'; echo; }
done

say "pkgsrc を取ってくる"
W=${HOME:-/tmp}/p9
mkdir -p "$W" && cd "$W" || exit 0
U=http://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz
got=no
for f in "hget $U" "curl -sSLo pkgsrc.tar.gz $U" "wget -q -O pkgsrc.tar.gz $U"; do
	set -- $f
	command -v "$1" >/dev/null 2>&1 || continue
	echo "  試す: $f"
	if [ "$1" = hget ]; then hget "$U" > pkgsrc.tar.gz 2>/dev/null; else eval "$f" 2>/dev/null; fi
	[ -s pkgsrc.tar.gz ] && { got=yes; break; }
done
if [ "$got" != yes ]; then echo "  !! 取ってこられない。ここで終わり"; exit 0; fi
echo "  取れた: $(ls -l pkgsrc.tar.gz | awk '{print $NF, $(NF-1)}')"

say "展開する"
if gunzip < pkgsrc.tar.gz | tar xf - 2>/dev/null || tar xzf pkgsrc.tar.gz 2>/dev/null; then
	echo "  展開できた: $(ls -d pkgsrc 2>/dev/null)"
else
	echo "  !! 展開できない"; exit 0
fi

say "bootstrap を走らせる"
cd "$W/pkgsrc/bootstrap" 2>/dev/null || { echo "  bootstrap が無い"; exit 0; }
SH=sh
for s in /bin/ape/psh /bin/ape/sh; do [ -x "$s" ] && SH=$s; done
echo "  使う shell: $SH"
"$SH" ./bootstrap --prefix "$W/pkg" --workdir "$W/work" --unprivileged > "$W/boot.log" 2>&1
rc=$?
echo "  rc=$rc"
say "最初に転んだ所"
# 末尾だけ見ると make の stopped の連鎖で埋まるので、最初の error を探す
grep -n -iE 'error|cannot|not found|No such|fail' "$W/boot.log" | head -12
echo "  --- log の末尾 25 行"
tail -25 "$W/boot.log" | sed 's/^/    /'
echo "  --- log の行数: $(wc -l < "$W/boot.log")"
exit 0
