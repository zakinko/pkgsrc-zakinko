# $NetBSD$

DISTNAME=	math-symbol-lists-1.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}math-symbol-lists-el-1.3
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=vspinu/}
GITHUB_PROJECT=	math-symbol-lists
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/vspinu/math-symbol-lists/
COMMENT=	Lists of Unicode mathematical symbols and latex commands
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/math-symbol-lists

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/math-symbol-lists
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/math-symbol-lists; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
