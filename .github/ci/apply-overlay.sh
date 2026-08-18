#!/bin/sh
# overlay/ の当て物を、上流 pkgsrc の同じカテゴリへ重ねる。
#
#   sh apply-overlay.sh <overlay ディレクトリ> <pkgsrc ツリー>
#
# overlay/<カテゴリ>/<パッケージ>/... を /usr/pkgsrc/<カテゴリ>/<パッケージ>/
# へ上書きし、patches/ を持つものには makepatchsum を走らせる。
#
# 同じ処理が三箇所にあった。build-on-bsd.sh (ゲストの中で走る) と
# run-in-qemu.sh (ホストから ssh でゲストへ流す) と、NetBSD-i386 の
# make-pkgsrc-tarball.sh (ツリーへ焼き込む) である。前の二つをここへ寄せた。
# 走る場所が違うだけで、やることは同じなので、実行の仕方だけを呼ぶ側に残す。
#
# makepatchsum に使う make は PKGMAKE で渡す。NetBSD のゲストなら base の
# make、bootstrap した箱なら $PREFIX/bin/bmake になる。渡されなければ在る
# 方を探す。

OVERLAY=${1:?usage: $0 <overlay dir> <pkgsrc tree>}
TREE=${2:?usage: $0 <overlay dir> <pkgsrc tree>}
PREFIX=${PREFIX:-/usr/pkg}

if [ -z "${PKGMAKE:-}" ]; then
	if [ -x "$PREFIX/bin/bmake" ]; then PKGMAKE=$PREFIX/bin/bmake
	else PKGMAKE=make
	fi
fi

[ -d "$OVERLAY" ] || { echo "overlay: $OVERLAY が無い。何もしない。"; exit 0; }

NEEDSUM=
for d in $(cd "$OVERLAY" && find . -mindepth 2 -maxdepth 2 -type d |
           sed 's|^\./||' | sort); do
	if [ ! -d "$TREE/$d" ]; then
		echo "!! overlay: $d が pkgsrc に無い。飛ばす。" >&2
		continue
	fi
	( cd "$OVERLAY/$d" && tar cf - . ) | ( cd "$TREE/$d" && tar xf - )
	echo "    overlay: $d"
	[ -d "$OVERLAY/$d/patches" ] && NEEDSUM="$NEEDSUM $d"
done

# patch を足したものは distinfo に SHA1 が要る。makepatchsum は
# pkgtools/digest の digest を呼び、無いと黙って何も書かずに成功する。
if [ -n "$NEEDSUM" ]; then
	if [ ! -x "$PREFIX/bin/digest" ] && [ -d "$TREE/pkgtools/digest" ]; then
		( cd "$TREE/pkgtools/digest" && "$PKGMAKE" install ) ||
			echo "!! pkgtools/digest が入らない" >&2
	fi
	for d in $NEEDSUM; do
		# ここで転けても止めない。distinfo が古いままでも、その package を
		# 組まなければ効かない。組んだときは patch のチェックサム不一致で
		# 必ず止まるので、黙って通ることはない。
		( cd "$TREE/$d" && "$PKGMAKE" makepatchsum ) ||
			echo "!! $d の makepatchsum に失敗" >&2
	done
fi
