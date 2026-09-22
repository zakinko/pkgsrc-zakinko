# $NetBSD$

DISTNAME=	sokoban-1.4.9
PKGNAME=	${EMACS_PKGNAME_PREFIX}sokoban-el-1.4.9
CATEGORIES=	devel
MASTER_SITES=	https://elpa.gnu.org/packages/
EXTRACT_SUFX=	.tar

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://elpa.gnu.org/packages/sokoban.html
COMMENT=	Implementation of Sokoban for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/sokoban

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/sokoban

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
