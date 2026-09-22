# $NetBSD$

DISTNAME=	paredit-26
PKGNAME=	${EMACS_PKGNAME_PREFIX}paredit-el-26
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=emacsmirror/}
GITHUB_PROJECT=	paredit
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://paredit.org/
COMMENT=	Minor mode for performing structured editing of S-expressions
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/paredit

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/paredit
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/paredit; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
