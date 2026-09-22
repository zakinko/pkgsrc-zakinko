# $NetBSD$

DISTNAME=	develock
PKGNAME=	${EMACS_PKGNAME_PREFIX}develock-el-0.47
CATEGORIES=	editors
MASTER_SITES=	https://www.jpl.org/ftp/pub/elisp/
DIST_SUBDIR=	develock-0.47
EXTRACT_SUFX=	.el.gz
WRKSRC=		${WRKDIR}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.jpl.org/ftp/pub/elisp/
COMMENT=	An Emacs minor mode for highlighting broken formatting rules
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/develock

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/develock
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/develock; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
