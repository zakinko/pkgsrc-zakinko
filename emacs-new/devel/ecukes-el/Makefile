# $NetBSD$

DISTNAME=	ecukes-0.6.18
PKGNAME=	${EMACS_PKGNAME_PREFIX}ecukes-el-0.6.18
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=ecukes/}
GITHUB_PROJECT=	ecukes
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/ecukes/ecukes/
COMMENT=	Cucumber for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}ansi-el-[0-9]*:../../devel/ansi-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}commander-el-[0-9]*:../../devel/commander-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}espuds-el-[0-9]*:../../devel/espuds-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}f-el-[0-9]*:../../devel/f-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}s-el-[0-9]*:../../devel/s-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/ecukes

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/ansi -L ${EMACS_LISPPREFIX}/commander -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/f -L ${EMACS_LISPPREFIX}/s -L ${EMACS_LISPPREFIX}/espuds -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/ecukes
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/ecukes; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
