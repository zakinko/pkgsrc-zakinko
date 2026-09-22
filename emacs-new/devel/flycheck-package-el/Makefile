# $NetBSD$

DISTNAME=	flycheck-package-0.14
PKGNAME=	${EMACS_PKGNAME_PREFIX}flycheck-package-el-0.14
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=purcell/}
GITHUB_PROJECT=	flycheck-package
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/purcell/flycheck-package/
COMMENT=	Flycheck checker for Emacs Lisp package metadata
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}flycheck-mode-[0-9]*:../../textproc/flycheck-mode
DEPENDS+=	${EMACS_PKGNAME_PREFIX}package-lint-el-[0-9]*:../../devel/package-lint-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/flycheck-package

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/package-lint -L ${EMACS_LISPPREFIX}/compat -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/flycheck-package
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/flycheck-package; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
