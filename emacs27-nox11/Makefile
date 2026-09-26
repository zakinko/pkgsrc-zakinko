# $NetBSD$

PKGREVISION=	1
PKGNAME=	${DISTNAME:S/emacs/emacs27/:S/-/-nox11-/}
CONFLICTS+=	emacs27-[0-9]*

FILESDIR=	${.CURDIR}/../../zakinko/emacs27/files
PATCHDIR=	${.CURDIR}/../../zakinko/emacs27/patches
PKGDIR=		${.CURDIR}/../../zakinko/emacs27
DISTINFO_FILE=	${.CURDIR}/../../zakinko/emacs27/distinfo

# minimal emacs without X, Cocoa, or any other GUI toolkit
CONFIGURE_ARGS+=	--without-all --without-x --without-ns
# but we want to gzip installed files
CONFIGURE_ARGS+=	--with-compress-install

.include "../../zakinko/emacs27/Makefile.common"
.include "../../mk/bsd.pkg.mk"
