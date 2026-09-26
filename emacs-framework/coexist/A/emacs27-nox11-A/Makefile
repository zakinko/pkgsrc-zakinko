# $NetBSD$

PKGREVISION=	1
PKGNAME=	${DISTNAME:S/emacs/emacs27/:S/-/-nox11-/}
# CONFLICTS は無い。EMACS_TAG に -nox11 が付き、X 版と path を共有しない。
EMACS_TAG=	27.2-nox11

FILESDIR=	${.CURDIR}/../../netbsd-i386-3e/emacs27-A/files
PATCHDIR=	${.CURDIR}/../../netbsd-i386-3e/emacs27-A/patches
PKGDIR=		${.CURDIR}/../../netbsd-i386-3e/emacs27-A
DISTINFO_FILE=	${.CURDIR}/../../netbsd-i386-3e/emacs27-A/distinfo

# minimal emacs without X, Cocoa, or any other GUI toolkit
CONFIGURE_ARGS+=	--without-all --without-x --without-ns
# but we want to gzip installed files
CONFIGURE_ARGS+=	--with-compress-install

.include "../../netbsd-i386-3e/emacs27-A/Makefile.common"
.include "../../mk/bsd.pkg.mk"
