# $NetBSD$

DISTNAME=	timu-caribbean-theme-v1.5
PKGNAME=	${EMACS_PKGNAME_PREFIX}timu-caribbean-theme-el-1.5
CATEGORIES=	devel
MASTER_SITES=	https://gitlab.com/aimebertrand/timu-caribbean-theme/-/archive/v${PKGVERSION_NOREV}/
EXTRACT_SUFX=	.tar.bz2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://gitlab.com/aimebertrand/timu-caribbean-theme
COMMENT=	Color theme with cyan as a dominant color
LICENSE=	mit

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/timu-caribbean-theme

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/timu-caribbean-theme
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/timu-caribbean-theme; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
