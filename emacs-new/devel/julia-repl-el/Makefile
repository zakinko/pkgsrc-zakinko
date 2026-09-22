# $NetBSD$

DISTNAME=	julia-repl-1.5.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}julia-repl-el-1.5.2
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=tpapp/}
GITHUB_PROJECT=	julia-repl
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/tpapp/julia-repl/
COMMENT=	Run an inferior Julia REPL in a terminal inside Emacs
LICENSE=	mit

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}julia-mode-[0-9]*:../../devel/julia-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}s-el-[0-9]*:../../devel/s-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/julia-repl

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

# upstream marks the file no-byte-compile
NO_BUILD=	yes

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/julia-repl
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/julia-repl; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
