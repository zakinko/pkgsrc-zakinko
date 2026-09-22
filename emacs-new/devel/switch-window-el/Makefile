# $NetBSD$

DISTNAME=	switch-window-1.6.2.20210808
PKGNAME=	${EMACS_PKGNAME_PREFIX}switch-window-el-1.6.2.20210808
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=dimitri/}
GITHUB_PROJECT=	switch-window
GITHUB_TAG=	8d9fe251d8d38b223d643df975876356ddfc1b98
WRKSRC=		${WRKDIR}/switch-window-8d9fe251d8d38b223d643df975876356ddfc1b98

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/dimitri/switch-window/
COMMENT=	Offer a customizable visual way to choose a window to switch to
LICENSE=	wtfpl	# licenses/wtfpl comes with this set

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/switch-window

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/switch-window
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/switch-window; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
