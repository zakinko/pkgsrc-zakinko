# $NetBSD$

DISTNAME=	actionscript-mode-7.2.2.20180527
PKGNAME=	${EMACS_PKGNAME_PREFIX}actionscript-mode-7.2.2.20180527
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=austinhaas/}
GITHUB_PROJECT=	actionscript-mode
GITHUB_TAG=	65abd58e198458a8e46748c5962c41d80d60c4ea
WRKSRC=		${WRKDIR}/actionscript-mode-65abd58e198458a8e46748c5962c41d80d60c4ea

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/austinhaas/actionscript-mode/
COMMENT=	major mode for GNU Emacs for editing Actionscript 3 files
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/actionscript-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/actionscript-mode
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/actionscript-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
