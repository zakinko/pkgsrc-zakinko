# $NetBSD$

DISTNAME=	groovy-emacs-modes-2.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}groovy-emacs-modes-2.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=Groovy-Emacs-Modes/}
GITHUB_PROJECT=	groovy-emacs-modes
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/Groovy-Emacs-Modes/groovy-emacs-modes/
COMMENT=	Groovy major mode, grails minor mode, and a groovy inferior mode
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}s-el-[0-9]*:../../devel/s-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/groovy-emacs-modes

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/s -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/groovy-emacs-modes
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/groovy-emacs-modes; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
