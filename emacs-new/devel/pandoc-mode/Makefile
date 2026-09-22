# $NetBSD$

DISTNAME=	pandoc-mode-2.90.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}pandoc-mode-2.90.2
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=joostkremers/}
GITHUB_PROJECT=	pandoc-mode
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://joostkremers.github.io/pandoc-mode/
COMMENT=	GNU Emacs minor mode for interacting with Pandoc
LICENSE=	modified-bsd

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}hydra-el-[0-9]*:../../editors/hydra-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/pandoc-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/hydra -L ${EMACS_LISPPREFIX}/lv -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/pandoc-mode
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/pandoc-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
