# $NetBSD$

PKGNAME=	${DISTNAME:S/emacs/emacs28/:S/-/-nox11-/}
# CONFLICTS は無い。EMACS_TAG に -nox11 が付き、X 版と path を共有しない。
EMACS_TAG=	28.2-nox11

# 上流の editors/emacs28-nox11 は PKGREVISION を持たなかった (0)。その +1。
# emacs28 側が 48 なのは上流が 47 だったからで、揃わないのはもとの二つが
# 揃っていなかったため。どちらも上流より大きければ pkgin は入れ替える。
PKGREVISION=	1

FILESDIR=	${.CURDIR}/../../netbsd-i386-3e/emacs28-A/files
PATCHDIR=	${.CURDIR}/../../netbsd-i386-3e/emacs28-A/patches
PKGDIR=		${.CURDIR}/../../netbsd-i386-3e/emacs28-A
DISTINFO_FILE=	${.CURDIR}/../../netbsd-i386-3e/emacs28-A/distinfo

# minimal emacs without X, Cocoa, or any other GUI toolkit
CONFIGURE_ARGS+=	--without-all --without-x --without-ns
# but we want to gzip installed files
CONFIGURE_ARGS+=	--with-compress-install

.include "../../netbsd-i386-3e/emacs28-A/Makefile.common"
.include "../../mk/bsd.pkg.mk"
