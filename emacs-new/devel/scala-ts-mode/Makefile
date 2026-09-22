# $NetBSD$

DISTNAME=	scala-ts-mode-1.0.0.20250418
PKGNAME=	${EMACS_PKGNAME_PREFIX}scala-ts-mode-1.0.0.20250418
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=KaranAhlawat/}
GITHUB_PROJECT=	scala-ts-mode
GITHUB_TAG=	c7671e10419261ef70b1820d3b970ad39f6fcfe2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/KaranAhlawat/scala-ts-mode
COMMENT=	Emacs Scala Mode via Tree-Sitter
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on app-editors/emacs-29
# XXX Gentoo also depends on dev-libs/tree-sitter-scala

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/scala-ts-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/scala-ts-mode
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/scala-ts-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
