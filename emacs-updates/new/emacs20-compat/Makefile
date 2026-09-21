# $NetBSD$

PKGNAME=	${EMACS_PKGNAME_PREFIX}emacs20-compat-20260922
CATEGORIES=	devel
DISTFILES=	# none

MAINTAINER=	pkgsrc-users@NetBSD.org
COMMENT=	Pieces of Emacs 21 to 26 that elisp written since needs on Emacs 20
LICENSE=	gnu-gpl-v3

# Everything in e20-compat.el is defined only when missing, and Emacs 21
# and later have all of it.
EMACS_VERSIONS_ACCEPTED=	emacs20

WRKSRC=		${WRKDIR}
NO_CONFIGURE=	yes

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}

do-extract:
	${CP} ${FILESDIR}/e20-compat.el ${WRKSRC}/

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} -batch -q --no-site-file -L . -l e20-compat \
		-f batch-byte-compile e20-compat.el

do-install:
	${INSTALL_DATA} ${WRKSRC}/e20-compat.el ${WRKSRC}/e20-compat.elc \
		${DESTDIR}${EMACS_LISPPREFIX}

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
