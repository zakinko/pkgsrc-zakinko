# $NetBSD$

DISTNAME=	ts-0.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}ts-el-0.3
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=alphapapa/}
GITHUB_PROJECT=	ts.el
GITHUB_TAG=	552936017cfdec89f7fc20c254ae6b37c3f22c5b
WRKSRC=		${WRKDIR}/ts.el-552936017cfdec89f7fc20c254ae6b37c3f22c5b

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/alphapapa/ts.el
COMMENT=	Emacs timestamp and date-time library
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}s-el-[0-9]*:../../devel/s-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/ts

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/s -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/ts
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/ts; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
