# $NetBSD$

PKGNAME=	${DISTNAME:S/emacs/emacs26/:S/-/-nox11-/}
# CONFLICTS は無い。EMACS_TAG に -nox11 が付き、X 版と path を共有しない。
EMACS_TAG=	26.3-nox11

FILESDIR=	${.CURDIR}/../../netbsd-i386-3e/emacs26-A/files
PATCHDIR=	${.CURDIR}/../../netbsd-i386-3e/emacs26-A/patches
PKGDIR=		${.CURDIR}/../../netbsd-i386-3e/emacs26-A
DISTINFO_FILE=	${.CURDIR}/../../netbsd-i386-3e/emacs26-A/distinfo

.include "../../netbsd-i386-3e/emacs26-A/Makefile.common"

PKGREVISION=	2

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
