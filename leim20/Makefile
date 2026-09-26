# $NetBSD$

VERSION=	20.7

DISTNAME=	leim-${VERSION}
PKGREVISION=	8
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GNU:=emacs/}
DISTFILES=	emacs-${VERSION}${EXTRACT_SUFX} ${DISTNAME}${EXTRACT_SUFX}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.gnu.org/software/emacs/emacs.html
COMMENT=	Libraries of Emacs Input Methods
LICENSE=	gnu-gpl-v2

DEPENDS+=	emacs20-${VERSION}{,nb[0-9]*}:../../editors/emacs20

# Not verified whether leim's own Makefile is parallel-safe; it runs emacs to
# byte-compile.  editors/leim21 does not set this, so it may well be
# unnecessary here too, but leave it until that has been checked.
MAKE_JOBS_SAFE=	no

WRKSRC=		${WRKDIR}/emacs-${VERSION}
GNU_CONFIGURE=	yes
USE_TOOLS+=	gmake

BUILD_DIRS=	leim

INSTALL_MAKE_FLAGS+=	prefix=${DESTDIR}${PREFIX}
INSTALLATION_DIRS+=	share/emacs/${VERSION}/leim

post-install:
	${CHMOD} -R go+rX ${DESTDIR}${PREFIX}/share/emacs/${VERSION}/leim
	${CHOWN} -R ${ROOT_USER} ${DESTDIR}${PREFIX}/share/emacs/${VERSION}/leim

.include "../../mk/bsd.pkg.mk"
