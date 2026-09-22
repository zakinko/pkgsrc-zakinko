# $NetBSD$

DISTNAME=	package-lint-0.26
PKGNAME=	${EMACS_PKGNAME_PREFIX}package-lint-el-0.26
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=purcell/}
GITHUB_PROJECT=	package-lint
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/purcell/package-lint/
COMMENT=	Linting library for Emacs Lisp package metadata
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}compat-el-[0-9]*:../../devel/compat-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/package-lint
USE_TOOLS+=	pax

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/compat -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/package-lint
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/package-lint; done
	cd ${WRKSRC}/. && ${PAX} -rw data ${DESTDIR}${EMACS_LISPPREFIX}/package-lint

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
