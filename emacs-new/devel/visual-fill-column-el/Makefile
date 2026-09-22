# $NetBSD$

DISTNAME=	visual-fill-column-2.7.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}visual-fill-column-el-2.7.1
CATEGORIES=	devel
MASTER_SITES=	https://codeberg.org/joostkremers/visual-fill-column/archive/
DISTFILES=	${PKGVERSION_NOREV}${EXTRACT_SUFX}
DIST_SUBDIR=	${DISTNAME}
WRKSRC=		${WRKDIR}/visual-fill-column

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://codeberg.org/joostkremers/visual-fill-column/
COMMENT=	GNU Emacs mode for wrapping visual-line-mode buffers at fill-column
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/visual-fill-column

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/visual-fill-column
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/visual-fill-column; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
