# $NetBSD: Makefile,v 1.3 2026/08/25 17:44:23 wiz Exp $

PKGNAME=	${DISTNAME:S/emacs/emacs30/:S/-/-nox11-/}
PKGREVISION=	1

# No CONFLICTS: with EMACS_TAG carrying the variant, this build shares
# no path with the X one.
EMACS_TAG=	${EMACS_VERSION}-nox11

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
