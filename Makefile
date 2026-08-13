# $NetBSD$
#
# zakinko の自作パッケージを置くローカルカテゴリ。
# 本家 pkgsrc ツリーと混ざらないように、独立したカテゴリとして切っている。

COMMENT=	Local packages maintained by zakinko

SUBDIR+=	github-keys
SUBDIR+=	meibo
SUBDIR+=	mule
SUBDIR+=	nss_stns
SUBDIR+=	stnsd

.include "../mk/misc/category.mk"
