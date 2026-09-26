# $NetBSD: Makefile,v 1.3 2012/10/07 17:41:40 asau Exp $

DISTNAME=	undo-tree-0.8.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}${DISTNAME}
CATEGORIES=	editors
MASTER_SITES=	https://elpa.gnu.org/packages/
EXTRACT_SUFX=	.tar

MAINTAINER=	pho@cielonegro.org
HOMEPAGE=	https://www.dr-qubit.org/undo-tree.html
COMMENT=	Treat Emacs undo history as a tree
LICENSE=	gnu-gpl-v3

USE_LANGUAGES=	# none
MESSAGE_SUBST+=	LISPDIR=${EMACS_LISPPREFIX}

# 0.8 needs Emacs 24.3 or later and the queue library from GNU ELPA.
EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}queue-el>=0.2:../../zakinko/queue-el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L ${EMACS_LISPPREFIX}/queue -f batch-byte-compile undo-tree.el

do-install:
	${INSTALL_DATA_DIR} ${DESTDIR}${EMACS_LISPPREFIX}
	${INSTALL_DATA} ${WRKSRC}/undo-tree.el ${WRKSRC}/undo-tree.elc \
		${DESTDIR}${EMACS_LISPPREFIX}

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
