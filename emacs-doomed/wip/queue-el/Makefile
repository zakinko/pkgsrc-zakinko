# $NetBSD$

DISTNAME=	queue-0.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME:S/queue/queue-el/}
CATEGORIES=	devel
MASTER_SITES=	https://elpa.gnu.org/packages/
EXTRACT_SUFX=	.tar

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://elpa.gnu.org/packages/queue.html
COMMENT=	Queue data structure for Emacs Lisp
LICENSE=	gnu-gpl-v3

USE_LANGUAGES=	# none

# undo-tree 0.8 needs it.  Emacs 24.1 or later.
EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-f batch-byte-compile queue.el

do-install:
	${INSTALL_DATA} ${WRKSRC}/queue.el ${WRKSRC}/queue.elc \
		${DESTDIR}${EMACS_LISPPREFIX}

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
