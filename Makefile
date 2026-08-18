# $NetBSD$
#
# zakinko の自作パッケージを置くローカルカテゴリ。
# 本家 pkgsrc ツリーと混ざらないように、独立したカテゴリとして切っている。

COMMENT=	Local packages maintained by zakinko

SUBDIR+=	autogen
SUBDIR+=	meibo
SUBDIR+=	mule
SUBDIR+=	nss_stns
SUBDIR+=	ntp4
SUBDIR+=	stnsd

.include "../mk/misc/category.mk"
