# $NetBSD$

DISTNAME=	vscode-dark-plus-emacs-theme-2.1.0.20260606
PKGNAME=	${EMACS_PKGNAME_PREFIX}vscode-dark-plus-emacs-theme-el-2.1.0.20260606
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=ianyepan/}
GITHUB_PROJECT=	vscode-dark-plus-emacs-theme
GITHUB_TAG=	c401b44809bfbf5928582efddc19ddda4f271ed4
WRKSRC=		${WRKDIR}/vscode-dark-plus-emacs-theme-c401b44809bfbf5928582efddc19ddda4f271ed4

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/ianyepan/vscode-dark-plus-emacs-theme/
COMMENT=	Accurate port of the default Visual Studio Code Dark+ theme for GNU Em
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/vscode-dark-plus-emacs-theme

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/vscode-dark-plus-emacs-theme
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/vscode-dark-plus-emacs-theme; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
