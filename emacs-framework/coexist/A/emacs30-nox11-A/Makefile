# $NetBSD: Makefile,v 1.6 2026/10/18 19:41:14 wiz Exp $

PKGNAME=	${DISTNAME:S/emacs/emacs30/:S/-/-nox11-/}
PKGREVISION=	5

CONFLICTS+=	emacs30-[0-9]*

FILESDIR=	${.CURDIR}/../../netbsd-i386-3e/emacs30-A/files
PATCHDIR=	${.CURDIR}/../../netbsd-i386-3e/emacs30-A/patches
PKGDIR=		${.CURDIR}/../../editors/emacs30
DISTINFO_FILE=	${.CURDIR}/../../netbsd-i386-3e/emacs30-A/distinfo

# minimal emacs without X, Cocoa, or any other GUI toolkit
CONFIGURE_ARGS+=	--without-all --without-x --without-ns
# but we want to gzip installed files and have module support
CONFIGURE_ARGS+=	--with-compress-install
CONFIGURE_ARGS+=	--with-modules

.include "../../netbsd-i386-3e/emacs30-A/Makefile.common"
.include "../../mk/bsd.pkg.mk"
