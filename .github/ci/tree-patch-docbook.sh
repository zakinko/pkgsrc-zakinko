#!/bin/sh
# DocBook の XSL が局所解決できず、man/html を作る package が軒並み転ぶ。
# 穴は二つあって、両方ふさがないと直らない。
#
# (1) catalog を誰も見ていない
#     mk/../xmlcatmgr/catalogs.mk は XML catalog を
#       XML_CATALOG="${LOCALBASE}/share/xml/catalog"
#     に置く。ところが textproc/libxml2 は --sysconfdir=${PKG_SYSCONFDIR} で
#     建つので、既定で読むのは ${PKG_SYSCONFDIR}/xml/catalog。場所が違う。
#     そして XML_CATALOG_FILES を渡している package は木の中にほぼ無い
#     (textproc/xmlto が SGML_CATALOG_FILES に XML の path を入れている。
#      変数名を取り違えた跡に見える)。
#
# (2) catalog を見ても、探している URI が載っていない
#     textproc/docbook-xsl が入れる catalog.xml は 8 行しかなく、覆うのは
#       http://cdn.docbook.org/release/xsl-nons/{1.79.2,current}/
#     の二つだけ。ところが dbus も xmlto も、まだ旧い
#       http://docbook.sourceforge.net/release/xsl/current/...
#     を参照している。
#
# 昔はこれでも通っていた。xsltproc がネットから取れたからである。今は取れない。
# pkgsrc の libxml2 の Makefile 自身が --with-http の脇に
# 「enable http ABI compatibility (feature is gone)」と書いている。dbus に
# 至っては xsltproc に --nonet を渡していて、最初からネットを使う気がない。
# 結果、dbus は
#     Message: Docbook XSL "manpages" not found, disabled automatically
#     Building XML docs : NO
# と静かに doc を作らずに進み、PLIST が man を期待しているので file-check で
# 転ぶ。xmlto のほうは外部実体を読めずその場で転ぶ。
#
# ここでは (2) を docbook-xsl の XML_ENTRIES で、(1) を dbus の
# CONFIGURE_ENV/MAKE_ENV でふさぐ。加えて xmlto の SUBST の段も直す
# (前の run で、これだけは効くことを実測した。docbook.sourceforge.net の
#  出現が 82801 行中ゼロになり、xmlto は通った)。
#
# 本家へ出す直しの検証を兼ねている。効かなければここで転ぶ。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
say() { printf '  %s\n' "$*"; }

# ------------------------------------------------------------------
# xmlto: 置換の段が post-build では自分の build に間に合わない
f=$TREE/textproc/xmlto/Makefile
if grep -q '^SUBST_STAGE\.fix-paths=.*post-build' "$f"; then
	sed -e '/^SUBST_STAGE\.fix-paths=/s/post-build/pre-configure/' "$f" > "$f.n"
	mv "$f.n" "$f"
	grep -q '^SUBST_STAGE\.fix-paths=.*pre-configure' "$f" ||
		{ echo "!! xmlto の置換が効いていない" >&2; exit 1; }
	say "xmlto: SUBST_STAGE.fix-paths を pre-configure へ"
else
	say "xmlto: post-build ではない。そのまま"
fi

# ------------------------------------------------------------------
# docbook-xsl: 旧 sourceforge の URI を catalog に足す
f=$TREE/textproc/docbook-xsl/Makefile
if ! grep -q 'docbook.sourceforge.net' "$f"; then
	awk '
	/^\.include "\.\.\/\.\.\/textproc\/xmlcatmgr\/catalogs\.mk"/ && !done {
		print "# dbus や xmlto がまだ参照している旧い URI を、局所の"
		print "# stylesheet へ向ける。上流の catalog.xml は cdn.docbook.org の"
		print "# 二つしか持っていない。"
		print "# xmlcatmgr の install.tmpl は add \"$1\" \"$2\" \"$3\" して shift を"
		print "# 三回する。エントリはきっかり 3 トークン。引数が一つの型だけが"
		print "# -- で埋める (catalogs.mk の nextCatalog がそれ)。rewriteURI は"
		print "# 引数が二つなので -- は付けない。行き先は textproc/docbook-xml に"
		print "# 倣って素の path で書く。"
		print "XML_ENTRIES+=\trewriteURI http://docbook.sourceforge.net/release/xsl/current/ ${XSLDIR}/"
		print "XML_ENTRIES+=\trewriteURI http://docbook.sourceforge.net/release/xsl-ns/current/ ${XSLDIR}/"
		print ""
		done = 1
	}
	{ print }
	' "$f" > "$f.n"
	mv "$f.n" "$f"
	grep -q 'docbook.sourceforge.net' "$f" ||
		{ echo "!! docbook-xsl に XML_ENTRIES が入っていない" >&2; exit 1; }
	say "docbook-xsl: 旧 URI の rewriteURI を足した"
else
	say "docbook-xsl: 既に旧 URI を持っている。そのまま"
fi

# ------------------------------------------------------------------
# dbus: catalog を実際に読ませる
f=$TREE/sysutils/dbus/Makefile
if ! grep -q 'XML_CATALOG_FILES' "$f"; then
	# bsd.pkg.mk は最後でなければならない。末尾に足すと後ろに回って効かない。
	# 実際、最初に cat >> で書いて偽の木で確かめたらそうなっていた。
	awk '
	/^\.include "\.\.\/\.\.\/mk\/bsd\.pkg\.mk"/ && !done {
		print "# libxml2 の既定は ${PKG_SYSCONFDIR}/xml/catalog だが、pkgsrc が"
		print "# catalog を置くのは ${PREFIX}/share/xml/catalog である。xsltproc に"
		print "# --nonet を渡しているので、ここを教えないと DocBook XSL が見つからず、"
		print "# meson が doc を黙って無効にし、PLIST と食い違って file-check で転ぶ。"
		print "CONFIGURE_ENV+=\tXML_CATALOG_FILES=${PREFIX}/share/xml/catalog"
		print "MAKE_ENV+=\tXML_CATALOG_FILES=${PREFIX}/share/xml/catalog"
		print ""
		done = 1
	}
	{ print }
	' "$f" > "$f.n"
	mv "$f.n" "$f"
	grep -q 'XML_CATALOG_FILES' "$f" ||
		{ echo "!! dbus に XML_CATALOG_FILES が入っていない" >&2; exit 1; }
	say "dbus: XML_CATALOG_FILES を渡すようにした"
else
	say "dbus: 既に XML_CATALOG_FILES を持っている。そのまま"
fi

# security/polkit の手当ては、ここではなく verify-NetworkManager.sh に在る。
# TREE_PATCH は bootstrap より前に走るので bmake がまだ無く、distinfo の
# SHA1 を自分で計算することになる。pkgsrc は digest -p という patch 専用の
# 数え方をしていて、sed '1d' | sha1 では合わない。実際に合わず
#
#   Ignoring patch file .../patch-src_polkitagent_polkitagenthelper-pam.c:
#     invalid checksum
#   ERROR: Patching failed due to modified or broken patch file(s)
#
# で Linux の build を壊した。自分で数えずに makepatchsum に数えさせる。
