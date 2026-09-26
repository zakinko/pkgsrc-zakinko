#!/bin/sh
# emacs24 が NetBSD 9.4 で dump に失敗する件。ASLR が原因かどうかを、
# 落ちる command をそのまま二度走らせて切り分ける。
PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/pkg/bin:/usr/pkg/sbin; export PATH
L=/tmp; mkdir -p $L
echo "=== 箱 ==="
uname -a
sysctl security.pax.aslr.global security.pax.aslr.enabled security.pax.mprotect.global
echo "=== emacs24-nox11 を build まで ==="
cd /usr/pkgsrc/zakinko/emacs24-nox11 || { echo "無い"; exit 1; }
make clean > /dev/null 2>&1
BATCH=1 make EMACS_TYPE=emacs24nox build < /dev/null > $L/e24.log 2>&1
echo "  build の rc=$?"
tail -4 $L/e24.log | cut -c1-100
W=$(make EMACS_TYPE=emacs24nox show-var VARNAME=WRKSRC 2>/dev/null | tail -1)
echo "=== WRKSRC=$W ==="
[ -x "$W/src/temacs" ] || { echo "  temacs が無い。ここで終わり"; exit 1; }
cd "$W/src" || exit 1
echo "=== 1. 印なしで dump を 10 回 ==="
paxctl temacs 2>&1 | head -3
ok=0; ng=0; i=0
while [ $i -lt 10 ]; do
	i=$((i+1))
	if ./temacs --batch --load loadup bootstrap > /dev/null 2>&1; then ok=$((ok+1)); else ng=$((ng+1)); fi
	rm -f emacs
done
echo "  通った $ok / 落ちた $ng"
echo "=== 2. paxctl +a を付けて 10 回 ==="
paxctl +a temacs
paxctl temacs 2>&1 | head -3
ok2=0; ng2=0; i=0
while [ $i -lt 10 ]; do
	i=$((i+1))
	if ./temacs --batch --load loadup bootstrap > /dev/null 2>&1; then ok2=$((ok2+1)); else ng2=$((ng2+1)); fi
	rm -f emacs
done
echo "  通った $ok2 / 落ちた $ng2"
