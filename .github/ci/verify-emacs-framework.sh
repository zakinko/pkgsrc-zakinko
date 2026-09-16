#!/bin/sh
# editors/emacs/modules.mk への変更を、手元と別の箱で踏む。
#
#	UPSTREAM_PKG=zakinko/emacs-framework \
#	VERIFY_SCRIPT=verify-emacs-framework.sh \
#	    sh run-in-qemu.sh i386-11.0
#
# 手元 (NetBSD 11.0/amd64) で一周は回してある。ここが見るのは **同じことが
# i386 でも起きるか** の一点で、package を網羅することではない。直しの形
# ごとに一つずつ選んである。
#
#	devel/apel        prefix が PKGNAME に乗る素の形
#	devel/flim        prefix の無い依存を名指していた
#	devel/zig-mode    GITHUB_PROJECT?= ${PKGBASE} で fetch が動く
#	textproc/dictem   install が ${PKGBASE}、PLIST が素の名前
#	editors/gnuserv   INSTALLATION_DIRS が ${PKGBASE}
#	www/emacs-w3m     configure に lisp の置き場を渡す
#
# 建つことと同じだけ、**入れた lisp に Emacs が届くか** を見る。置き場を
# 動かす変更なので、そこを見ないと「建った」しか言えない。
#
# VERIFY_OPTS に package を並べると差し替わる。

set -e

TREE=${TREE:-/usr/pkgsrc}
PREFIX=${PREFIX:-/usr/pkg}
OUT=${OUT:-/var/tmp/emacs-framework}
PATH=/sbin:/usr/sbin:/bin:/usr/bin:$PREFIX/bin:$PREFIX/sbin
export PATH
unset PKG_PATH
mkdir -p "$OUT"

SRC=$TREE/zakinko/emacs-framework
[ -d "$SRC" ] || { echo "$SRC が無い。UPSTREAM_PKG=zakinko/emacs-framework で送ること"; exit 1; }

EMACS_TYPE=${EMACS_TYPE:-emacs30nox}
PKGS=${VERIFY_OPTS:-}
[ -n "$PKGS" ] || PKGS="devel/apel devel/flim devel/zig-mode textproc/dictem editors/gnuserv www/emacs-w3m"

echo "=== 当てる先の版を見る ==="
# 木を丸ごと置き換える設計にしていたら、初回で捕まった。
#
#	ツリー: modules.mk,v 1.40 2026/08/25
#	手元  : modules.mk,v 1.42 2026/09/14
#
# cdn.netbsd.org の current/pkgsrc.tar.gz は git の trunk より遅れる。
# file を置き換えると、その差にある上流の変更を黙って戻してしまう。
# 差分を当てる形にした。送る物とも揃う。版が違うことは止める理由には
# しない (当たるなら当たる) が、読めるように出す。
for f in editors/emacs/modules.mk mk/pbulk/pbulk-index.mk; do
	b=${f##*/}
	printf '  %-28s ツリー %s\n' "$f" "$(sed -n '1p' "$TREE/$f" | sed 's/.*,v //;s/ Exp \$//')"
	printf '  %-28s 手元   %s\n' "" "$(sed -n '1p' "$SRC/$b.orig" | sed 's/.*,v //;s/ Exp \$//')"
done

echo "=== 枠組みを当てる ==="
# 木がこちらの .orig と同じ版なら差分を当てる。違っていて差分が当たらない
# なら、.orig (上流の現物) を土台にしたこちらの file をそのまま置く。
#
# どちらを取ったかを必ず出す。file を置いた場合、**その file の外に在る
# 上流の変更は入っていない**ので、測ったものが何なのかが変わる。黙って
# 置き換えると、それが分からなくなる。
for f in editors/emacs/modules.mk mk/pbulk/pbulk-index.mk; do
	b=${f##*/}
	if patch -f -C "$TREE/$f" "$SRC/$b.diff" >/dev/null 2>&1; then
		patch -f "$TREE/$f" "$SRC/$b.diff" >/dev/null 2>&1
		echo "  差分を当てた   $f"
	else
		# 木の版は **置き換える前に** 読む。あとで読むと、置いた
		# こちらの file の版を「木は…だった」として出してしまう。
		# 一度そうなって、log が 1.42 を 1.42 で置いたと言っていた。
		was=$(sed -n '1p' "$TREE/$f" | sed 's/.*,v //;s/ Exp \$//')
		cp "$SRC/$b" "$TREE/$f"
		echo "  ★ 差分が当たらないので file を置いた   $f"
		echo "     土台は $(sed -n '1p' "$SRC/$b.orig" | sed 's/.*,v //;s/ Exp \$//')"
		echo "     木は   $was だった"
		echo "     この file に限り、木の側の版は測っていない"
	fi
done

echo "=== package の直しを当てる ==="
fail=0
for d in "$SRC"/pkg-fixes/*.diff; do
	[ -f "$d" ] || continue
	n=${d##*/}
	# 空当てで見てから当てる。-f が無いと当たらない相手に問い返して
	# 止まらなくなる。入力は -i で渡す (< と併用すると後ろが勝つ)。
	if (cd "$TREE" && patch -p0 -f -C -i "$d" >/dev/null 2>&1); then
		if (cd "$TREE" && patch -p0 -f -i "$d" >/dev/null 2>&1); then
			echo "  当てた   $n"
		else
			echo "  ★ 当たらない $n"; fail=1
		fi
	else
		echo "  ★ 空当てで落ちる $n (木の側が動いた可能性)"
		fail=1
	fi
done
[ "$fail" = 0 ] || echo "  (当たらなかったものが在る。続けるが結果はその分だけ弱い)"

echo "=== pbulk が版ごとに並べるか ==="
( cd "$TREE/devel/apel" && make pbulk-index 2>/dev/null | grep '^PKGNAME=' ) || true

echo "=== 建てる (EMACS_TYPE=$EMACS_TYPE) ==="
R=$OUT/result.txt
: > "$R"
for p in $PKGS; do
	echo "--- $p"
	log=$OUT/${p##*/}.log
	if ( cd "$TREE/$p" && make clean >/dev/null 2>&1;
	     cd "$TREE/$p" && make package-install EMACS_TYPE="$EMACS_TYPE" \
	        BINPKG_SITES="${BINPKG_SITES:-}" ) > "$log" 2>&1
	then
		n=$(cd "$TREE/$p" && make show-var VARNAME=PKGNAME EMACS_TYPE="$EMACS_TYPE")
		printf '%s\tOK\t%s\n' "$p" "$n" >> "$R"
	else
		if grep -q 'files are in the PLIST but not in' "$log"; then
			printf '%s\tNG-PLIST\n' "$p" >> "$R"
		else
			printf '%s\tNG-BUILD\t%s\n' "$p" \
				"$(grep -m1 'Error code' "$log" | tr -d '\n')" >> "$R"
		fi
		# 転けた run が、診断に要る行を自分で捨てないようにする。
		# 末尾だけ出すと、依存の版と configure の結論はその外に在る。
		# 落とすのは `: found` で終わる Tool dependency だけ。**NOT found
		# を落とさない形に限る**（全部落として肝心の一行を埋めた例が在る）。
		echo "  -- 依存と configure --"
		grep -E '^(=> (Full|Build|Tool) dependency|===> Configuring)' "$log" \
			| grep -vE '^=> Tool dependency .*: found$' | tail -20
		echo "  -- 末尾 --"
		tail -40 "$log"
	fi
done

echo "=== 入れた lisp に Emacs が届くか ==="
# 置き場を版の下へ動かす変更なので、ここが本題。建っただけでは足りない。
E=$PREFIX/bin/emacs
if [ -x "$E" ]; then
	# -Q は --no-site-lisp を含む。site-lisp が空に見えて「届かない」と
	# 誤診した。-q で測る。
	$E -batch -q --eval '(dolist (d load-path) (when (string-match-p "site-lisp" d) (princ (format "  %s\n" d))))' 2>&1 | head -12
	for l in path-util poe; do
		$E -batch -q --eval "(princ (format \"  %-10s %s\n\" \"$l\" (or (locate-library \"$l\") \"NOT FOUND\")))" 2>&1 | tail -1
	done
else
	echo "  emacs が入っていない"
fi

echo
echo "=== 結果 ==="
cat "$R"
! grep -q 'NG-' "$R"
