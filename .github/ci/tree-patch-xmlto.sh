#!/bin/sh
# textproc/xmlto は自分の man を build 中に生成する。
#
#   FORMAT_DIR=./format /bin/sh ./xmlto --skip-validation -o man/man1 man doc/xmlto.xml
#
# その format/docbook/* が
#   http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl
# を import していて、xsltproc はこれを取得できない。資源は在って curl は 200 を
# 返すが、http:// が https:// へ redirect されるようになっており、libxml2 の
# nanohttp は TLS を話せない。手元の macOS でも CI と同じ error を再現した。
#
#   error : Unknown IO error
#   warning: failed to load external entity "http://docbook.sourceforge.net/..."
#
# pkgsrc の Makefile には、この URL を局所の docbook-xsl へ書き換える置換が
# 既に在る。ところが段が post-build で、自分の build には間に合っていない。
# 同じ木の sysutils/dbus は同種の置換を pre-configure でやっている。
# 段を pre-configure へ動かす。
#
# これは本家へ出す直しの検証を兼ねる。効かなければここで転ぶ。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
f=$TREE/textproc/xmlto/Makefile
[ -f "$f" ] || { echo "!! $f が無い" >&2; exit 1; }

before=$(grep -c '^SUBST_STAGE\.fix-paths=.*post-build' "$f" || true)
if [ "$before" -eq 0 ]; then
	echo "xmlto: post-build ではない。既に直っているか形が変わった。そのまま進む"
	grep -n '^SUBST_STAGE\.fix-paths=' "$f" || true
	exit 0
fi

sed -e '/^SUBST_STAGE\.fix-paths=/s/post-build/pre-configure/' "$f" > "$f.new"
mv "$f.new" "$f"

# 黙って効かない形にならないよう、変わったことを機械で確かめる
after=$(grep -c '^SUBST_STAGE\.fix-paths=.*pre-configure' "$f" || true)
[ "$after" -eq 1 ] || { echo "!! 置換が効いていない" >&2; exit 1; }
echo "xmlto: SUBST_STAGE.fix-paths を pre-configure へ動かした"
grep -n '^SUBST_STAGE\.fix-paths=' "$f"
