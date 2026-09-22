# $NetBSD$

DISTNAME=	burly-0.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}burly-el-0.3
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=alphapapa/}
GITHUB_PROJECT=	burly.el
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/burly.el-0.3

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/alphapapa/burly.el
COMMENT=	Save and restore frames and windows with their buffers in Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/burly

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/burly
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/burly; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
