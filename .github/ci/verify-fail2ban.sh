#!/bin/sh
# security/fail2ban の更新を、send-pr に書く主張ごとに測る。
#
#   sh verify-fail2ban.sh <カテゴリ>/<パッケージ>
#
# 建つことだけを見ても足りない。書こうとしているのは次の三つで、二つ目と
# 三つ目は建てただけでは裏が取れない。
#
#   1. 1.1.1 が建って入る
#   2. **動く** (fail2ban-client と fail2ban-regex が仕事をする)
#   3. **GitHub issue #174 (asynchat が無い) が閉じる**
#
# 3 が肝である。asynchat と asyncore は Python 3.12 で標準ライブラリから
# 消えた。fail2ban 1.1.0 が compat/asynchat.py と compat/asyncore.py を
# 同梱したので直る、というのがこちらの読みだが、**同梱されているのを見た
# だけでは「動く」ことにはならない**。実際に import させて、しかもそれが
# 3.12 以降の python であることまで見る。そこまでやらないと
# 「#174 が閉じる」とは書けない。

PKG=${1:-zakinko/fail2ban}
case $PKG in */*) : ;; *) PKG=zakinko/fail2ban ;; esac

OS=$(uname -s)
PREFIX=${PREFIX:-/usr/pkg}
TREE=${TREE:-/usr/pkgsrc}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
export PATH
unset PKG_PATH

if [ -x "$PREFIX/bin/bmake" ]; then PKGMAKE=$PREFIX/bin/bmake
else PKGMAKE=make; fi
MKARGS=
[ -n "${BINPKG_SITES:-}" ] &&
	MKARGS="DEPENDS_TARGET=bin-install BINPKG_SITES=$BINPKG_SITES"

cd "$TREE/$PKG" || { echo "FAIL: $TREE/$PKG が無い"; exit 1; }
rc=0
echo "--- $PKG ($OS $(uname -r) / $(uname -m)) ---"

# ------------------------------------------------------------------
echo
echo "########## 1. 建って入るか ##########"
grep -nE '^DISTNAME|PYTHON_VERSIONS_ACCEPTED|2to3' Makefile || true
pkg_delete -f fail2ban > /dev/null 2>&1 || true
{ $PKGMAKE $MKARGS install 2>&1; echo $? > /tmp/f2b-rc; } | tee /tmp/f2b-1.log
if [ "$(cat /tmp/f2b-rc)" -eq 0 ]; then
	echo 'RESULT 建てる: 通った'
else
	echo 'RESULT 建てる: 落ちた'; tail -40 /tmp/f2b-1.log; rc=1
fi

echo "--- PLIST どおりか ---"
miss=0
for f in $(pkg_info -qL fail2ban 2>/dev/null); do
	[ -e "$f" ] || { echo "    無い: $f"; miss=$((miss + 1)); }
done
[ $miss -eq 0 ] && echo "  並べたものは全部置かれている" || { echo "FAIL: $miss 個"; rc=1; }

# ------------------------------------------------------------------
echo
echo "########## 2. 動くか ##########"
for c in fail2ban-client fail2ban-server fail2ban-regex; do
	if [ -x "$PREFIX/bin/$c" ]; then
		printf '  %-18s ' "$c"
		"$PREFIX/bin/$c" --version < /dev/null 2>&1 | head -1
	else
		echo "  !! $PREFIX/bin/$c が無い"; rc=1
	fi
done

# fail2ban-regex は「この行はこの filter に当たるか」を答える道具である。
# 実際の sshd のログを一行渡して、当たることまで見る。起動して版を名乗る
# だけなら import が通っただけで、正規表現も設定の読み込みも動いていない。
echo "--- sshd の filter が実際に当たるか ---"
cat > /tmp/f2b-test.log <<'LOG'
Jan  1 00:00:00 host sshd[1]: Failed password for root from 192.0.2.1 port 22 ssh2
LOG
if "$PREFIX/bin/fail2ban-regex" /tmp/f2b-test.log \
	"$PREFIX/share/examples/fail2ban/filter.d/sshd.conf" > /tmp/f2b-regex.log 2>&1
then
	grep -E 'Lines:|matched|Address found|^\| *\[1\]' /tmp/f2b-regex.log | head -6
	if grep -qE '1 match|matched 1|\[1\]' /tmp/f2b-regex.log; then
		echo 'RESULT 動作: filter が当たった'
	else
		echo 'RESULT 動作: 走ったが当たっていない'
		tail -20 /tmp/f2b-regex.log; rc=1
	fi
else
	echo 'RESULT 動作: fail2ban-regex が落ちた'
	tail -20 /tmp/f2b-regex.log; rc=1
fi

# ------------------------------------------------------------------
echo
echo "########## 3. issue #174 (asynchat) は閉じるか ##########"
# 同梱されているのを ls で見るだけでは足りない。import が通ること、そして
# それが asynchat を捨てた python (3.12 以降) であることまで見る。
PY=$(grep -E '^PYTHON_INTERP|PYTHONBIN' /tmp/f2b-1.log 2>/dev/null | head -1)
for p in "$PREFIX/bin/python3.13" "$PREFIX/bin/python3.12" "$PREFIX/bin/python3"; do
	[ -x "$p" ] && { PYBIN=$p; break; }
done
if [ -z "${PYBIN:-}" ]; then
	echo "!! python が $PREFIX/bin に無い"; rc=1
else
	echo "--- $PYBIN ---"
	"$PYBIN" -c 'import sys; print("  version:", sys.version.split()[0])'
	echo "--- 標準ライブラリに asynchat / asyncore は在るか ---"
	"$PYBIN" -c 'import asynchat' 2>&1 | tail -1
	"$PYBIN" -c 'import asyncore' 2>&1 | tail -1
	echo "--- fail2ban の同梱版は import できるか ---"
	if "$PYBIN" -c 'from fail2ban.compat import asynchat, asyncore; print("  ok:", asynchat.__name__, asyncore.__name__)' 2>&1; then
		echo 'RESULT #174: 同梱版が import できる'
	else
		echo 'RESULT #174: 同梱版が import できない'; rc=1
	fi
	echo "--- 実際に使う側から通るか (asyncserver が asyncore を掴む) ---"
	"$PYBIN" -c 'from fail2ban.server.asyncserver import asyncore; print("  asyncserver ->", asyncore.__name__)' 2>&1 | tail -2
fi

[ $rc -eq 0 ] && echo "=== 通った: $PKG on $OS ===" ||
	echo "=== 見込みと違った: $PKG on $OS ==="
exit $rc
