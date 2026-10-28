# $NetBSD: Makefile,v 1.7 2026/10/14 19:32:13 markd Exp $

PKGNAME=	${DISTNAME:S/emacs/emacs29/:S/-/-nox11-/}
PKGREVISION=	3

CONFLICTS+=	emacs29-[0-9]*

FILESDIR=	${.CURDIR}/../../netbsd-i386-3e/emacs29-A/files
PATCHDIR=	${.CURDIR}/../../netbsd-i386-3e/emacs29-A/patches
PKGDIR=		${.CURDIR}/../../editors/emacs29
DISTINFO_FILE=	${.CURDIR}/../../netbsd-i386-3e/emacs29-A/distinfo

# minimal emacs without X, Cocoa, or any other GUI toolkit
CONFIGURE_ARGS+=	--without-all --without-x --without-ns
# but we want to gzip installed files and have module support
CONFIGURE_ARGS+=	--with-compress-install
CONFIGURE_ARGS+=	--with-modules

PLIST.nonative=		yes

.include "../../netbsd-i386-3e/emacs29-A/Makefile.common"
.include "../../mk/bsd.pkg.mk"
