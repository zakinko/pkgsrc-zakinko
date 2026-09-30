# $NetBSD$

DISTNAME=	cl-lib-0.6.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}cl-lib-el-0.6.1
CATEGORIES=	devel
MASTER_SITES=	https://elpa.gnu.org/packages/
EXTRACT_SUFX=	.el.lz

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://elpa.gnu.org/packages/cl-lib.html
COMMENT=	Forward compatibility cl-lib for Emacs before 24.3
LICENSE=	gnu-gpl-v3

# Emacs 24.3 and later bundle cl-lib; this is for the Emacsen before it
# that pkgsrc still carries, and for XEmacs.
EMACS_VERSIONS_ACCEPTED=	emacs20 xemacs214 xemacs214nox xemacs215 xemacs215nox

WRKSRC=		${WRKDIR}
NO_CONFIGURE=	yes
USE_TOOLS+=	lzip

# a single lzip-compressed file; pkgsrc's extract only knows tar.lz
do-extract:
	lzip -dc ${DISTDIR}/${DISTFILES} > ${WRKSRC}/cl-lib.el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} -batch -q --no-site-file \
		-f batch-byte-compile cl-lib.el

do-install:
	${INSTALL_DATA} ${WRKSRC}/cl-lib.el ${WRKSRC}/cl-lib.elc \
		${DESTDIR}${EMACS_LISPPREFIX}

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
