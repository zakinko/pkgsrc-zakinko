# $NetBSD$

DISTNAME=	emacs-el-fetch-3.3.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}emacs-el-fetch-el-3.3.0
CATEGORIES=	devel
MASTER_SITES=	https://gitlab.com/xgqt/emacs-el-fetch/-/archive/${PKGVERSION_NOREV}/
EXTRACT_SUFX=	.tar.bz2
WRKSRC=		${WRKDIR}/${DISTNAME}/src/el-fetch

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://gitlab.com/xgqt/emacs-el-fetch/
COMMENT=	Show system information in Neofetch-like style inside Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/emacs-el-fetch

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/emacs-el-fetch
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/emacs-el-fetch; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
