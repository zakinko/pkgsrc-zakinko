# $NetBSD$

PKGREVISION=	4
PKGNAME=	${DISTNAME:S/emacs/emacs23/:S/-/-nox11-/}
CONFLICTS+=	emacs23-[0-9]*

FILESDIR=	${.CURDIR}/../../zakinko/emacs23/files
PATCHDIR=	${.CURDIR}/../../zakinko/emacs23/patches
PKGDIR=		${.CURDIR}/../../zakinko/emacs23
DISTINFO_FILE=	${.CURDIR}/../../zakinko/emacs23/distinfo

.include "../../zakinko/emacs23/Makefile.common"

CONFIGURE_ARGS+=	--without-dbus
CONFIGURE_ARGS+=	--without-xml2
CONFIGURE_ARGS+=	--without-gnutls
CONFIGURE_ARGS+=	--without-rsvg
CONFIGURE_ARGS+=	--without-gconf
CONFIGURE_ARGS+=	--without-imagemagick
CONFIGURE_ARGS+=	--without-xaw3d
CONFIGURE_ARGS+=	--without-xft --without-libotf --without-m17n-flt
CONFIGURE_ARGS+=	--without-ns

CONFIGURE_ARGS+=	--without-x
CONFIGURE_ARGS+=	--without-xpm
CONFIGURE_ARGS+=	--without-jpeg
CONFIGURE_ARGS+=	--without-tiff
CONFIGURE_ARGS+=	--without-gif
CONFIGURE_ARGS+=	--without-png

.include "../../mk/bsd.pkg.mk"
