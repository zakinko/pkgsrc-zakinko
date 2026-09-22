# $NetBSD$

DISTNAME=	cmake-font-lock-0.1.13
PKGNAME=	${EMACS_PKGNAME_PREFIX}cmake-font-lock-el-0.1.13
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=Lindydancer/}
GITHUB_PROJECT=	cmake-font-lock
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/Lindydancer/cmake-font-lock
COMMENT=	Advanced, type aware, highlight support for CMake
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-build/cmake
# XXX dependency cmake-mode is not in pkgsrc

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/cmake-font-lock

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/cmake-font-lock
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/cmake-font-lock; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
