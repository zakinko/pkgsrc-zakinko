# $NetBSD$

DISTNAME=	ninja-mode-1.12.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}ninja-mode-1.12.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=ninja-build/}
GITHUB_PROJECT=	ninja
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/ninja-1.12.1/misc

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/ninja-build/ninja/
COMMENT=	GNU Emacs mode for handling Ninja build files
LICENSE=	apache-2.0

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-build/ninja-1.11.1-r4

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/ninja-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile ninja-mode.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} ninja-mode.el ${DESTDIR}${EMACS_LISPPREFIX}/ninja-mode
	cd ${WRKSRC} && for f in ninja-mode.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/ninja-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
