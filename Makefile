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
SUBDIR+=	emacs20
SUBDIR+=	emacs26
SUBDIR+=	emacs26-nox11
SUBDIR+=	emacs27
SUBDIR+=	emacs27-nox11
SUBDIR+=	emacs28
SUBDIR+=	emacs28-nox11
SUBDIR+=	fail2ban
SUBDIR+=	libuuid
SUBDIR+=	meibo
SUBDIR+=	mule
SUBDIR+=	nss_stns
SUBDIR+=	ntp4
SUBDIR+=	stnsd
SUBDIR+=	xwpe
SUBDIR+=	zls

.include "../mk/misc/category.mk"
