# $NetBSD: Makefile,v 1.1 2026/08/25 17:23:51 wiz Exp $

PKGNAME=	${DISTNAME:S/emacs/emacs31/:S/-/-nox11-/}
PKGREVISION=	1

CONFLICTS+=	emacs31-[0-9]*

FILESDIR=	${.CURDIR}/../../netbsd-i386-3e/emacs31-A/files
PATCHDIR=	${.CURDIR}/../../netbsd-i386-3e/emacs31-A/patches
PKGDIR=		${.CURDIR}/../../editors/emacs31
DISTINFO_FILE=	${.CURDIR}/../../netbsd-i386-3e/emacs31-A/distinfo

# minimal emacs without X, Cocoa, or any other GUI toolkit
CONFIGURE_ARGS+=	--without-all --without-x --without-ns
# but we want to gzip installed files and have module support
CONFIGURE_ARGS+=	--with-compress-install
CONFIGURE_ARGS+=	--with-modules

.include "../../netbsd-i386-3e/emacs31-A/Makefile.common"
.include "../../mk/bsd.pkg.mk"
