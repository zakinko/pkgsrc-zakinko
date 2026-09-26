# $NetBSD: Makefile,v 1.6 2026/09/25 09:48:06 wiz Exp $

DISTNAME=	ecb-2.52
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME}
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=ecb-home/}
GITHUB_PROJECT=	ecb
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/ecb-home/ecb
COMMENT=	Emacs Code Browser
LICENSE=	gnu-gpl-v2

USE_TOOLS+=	gmake makeinfo bash pax
INFO_FILES=	yes
# CEDET (semantic, eieio, speedbar) has been part of Emacs since 23.2,
# and ECB 2.5x is the fork that follows the bundled one.
EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

MAKE_FLAGS+=	EMACS=${EMACS_BIN:Q} CEDET= SHELL=${TOOLS_PATH.bash}
BUILD_TARGET=	ecb online-help

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/ecb ${EMACS_INFOPREFIX}

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/ecb
	cd ${WRKSRC} && ${PAX} -rw -pp ecb-images ${DESTDIR}${EMACS_LISPPREFIX}/ecb
	${INSTALL_DATA} ${WRKSRC}/info-help/ecb.info* ${DESTDIR}${EMACS_INFOPREFIX}

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
