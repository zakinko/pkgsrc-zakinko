# $NetBSD$

PKGNAME=	${DISTNAME:S/emacs/emacs28/:S/-/-nox11-/}
CONFLICTS+=	emacs28-[0-9]*

# 上流の editors/emacs28-nox11 は PKGREVISION を持たなかった (0)。その +1。
# emacs28 側が 48 なのは上流が 47 だったからで、揃わないのはもとの二つが
# 揃っていなかったため。どちらも上流より大きければ pkgin は入れ替える。
PKGREVISION=	1

FILESDIR=	${.CURDIR}/../../zakinko/emacs28/files
PATCHDIR=	${.CURDIR}/../../zakinko/emacs28/patches
PKGDIR=		${.CURDIR}/../../zakinko/emacs28
DISTINFO_FILE=	${.CURDIR}/../../zakinko/emacs28/distinfo

# minimal emacs without X, Cocoa, or any other GUI toolkit
CONFIGURE_ARGS+=	--without-all --without-x --without-ns
# but we want to gzip installed files
CONFIGURE_ARGS+=	--with-compress-install

.include "../../zakinko/emacs28/Makefile.common"
.include "../../mk/bsd.pkg.mk"
