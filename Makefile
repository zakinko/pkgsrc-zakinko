# $NetBSD$
#
# zakinko の自作パッケージを置くローカルカテゴリ。
# 本家 pkgsrc ツリーと混ざらないように、独立したカテゴリとして切っている。

COMMENT=	Local packages maintained by zakinko

SUBDIR+=	anthy
SUBDIR+=	anthy-elisp
SUBDIR+=	anthy-unicode
SUBDIR+=	anthy-unicode-elisp
SUBDIR+=	augeas
SUBDIR+=	autogen
SUBDIR+=	bazel9
SUBDIR+=	emacs20
SUBDIR+=	emacs21
SUBDIR+=	emacs21-nox11
SUBDIR+=	emacs22
SUBDIR+=	emacs22-nox11
SUBDIR+=	emacs23
SUBDIR+=	emacs23-nox11
SUBDIR+=	emacs24
SUBDIR+=	emacs24-nox11
SUBDIR+=	emacs25
SUBDIR+=	emacs25-nox11
SUBDIR+=	emacs26
SUBDIR+=	emacs26-nox11
SUBDIR+=	emacs27
SUBDIR+=	emacs27-nox11
SUBDIR+=	emacs28
SUBDIR+=	emacs28-nox11
SUBDIR+=	fail2ban
SUBDIR+=	fcitx5-mozc
SUBDIR+=	ibus-mozc
SUBDIR+=	libuuid
SUBDIR+=	meibo
SUBDIR+=	mozc-elisp
SUBDIR+=	mozc-elisp226
SUBDIR+=	mozc-elisp333
SUBDIR+=	mozc-elisp334
SUBDIR+=	mozc-renderer
SUBDIR+=	mozc-renderer333
SUBDIR+=	mozc-server
SUBDIR+=	mozc-server226
SUBDIR+=	mozc-server333
SUBDIR+=	mozc-server334
SUBDIR+=	mozc-tool
SUBDIR+=	mozc-tool333
SUBDIR+=	mule
SUBDIR+=	mule2
SUBDIR+=	nss_stns
SUBDIR+=	ntp4
SUBDIR+=	openjdk25
SUBDIR+=	openjdk28
SUBDIR+=	stnsd
SUBDIR+=	uim-mozc
SUBDIR+=	xwpe
SUBDIR+=	zls

.include "../mk/misc/category.mk"
