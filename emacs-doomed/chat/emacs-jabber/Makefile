# $NetBSD: Makefile,v 1.11 2026/09/25 09:48:05 wiz Exp $

DISTNAME=		emacs-jabber-0.8.92
PKGNAME=		${EMACS_PKGNAME_PREFIX}${DISTNAME:S/emacs-//}
CATEGORIES=		chat
MASTER_SITES=		${MASTER_SITE_SOURCEFORGE:=emacs-jabber/}
EXTRACT_SUFX=		.tar.bz2

MAINTAINER=		aran@100acres.us
HOMEPAGE=		https://emacs-jabber.sourceforge.net/
COMMENT=		Jabber client for Emacs
LICENSE=		gnu-gpl-v2 # or later

GNU_CONFIGURE=		yes
INFO_FILES=		YES

CONFIGURE_ARGS+=	--with-lispdir=${EMACS_LISPPREFIX}
# configure has no --with-gconf; the only gconf options are
# --with-gconf-source and --with-gconf-schema-file-dir, so --without-gconf
# only produced "unrecognized options" while gconftool-2 still ran.  It is
# called only when GCONF_SCHEMA_INSTALL_SOURCE is empty.
CONFIGURE_ENV+=		GCONF_SCHEMA_INSTALL_SOURCE=none
CONFIGURE_ARGS+=	--disable-schemas-install
CONFIGURE_ENV+=		EMACS=${EMACS_BIN}

TEST_TARGET=		check

MAKE_JOBS_SAFE=		no

DEPENDS+=		${EMACS_PKGNAME_PREFIX}elisp-compat-[0-9]*:../../devel/elisp-compat

EMACS_VERSIONS_ACCEPTED=	emacs20 xemacs214 xemacs215

# net-utils, mule-ucs for xemacs
EMACS_MODULES=		base
.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
