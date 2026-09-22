# $NetBSD$

DISTNAME=	expand-region-1.0.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}expand-region-el-1.0.0
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=magnars/}
GITHUB_PROJECT=	expand-region.el
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/expand-region.el-1.0.0

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/magnars/expand-region.el/
COMMENT=	Emacs extension to increase selected region by semantic units
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/expand-region

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/expand-region
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/expand-region; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
