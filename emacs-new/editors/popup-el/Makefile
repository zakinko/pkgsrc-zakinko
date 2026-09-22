# $NetBSD$

DISTNAME=	popup-0.5.9
PKGNAME=	${EMACS_PKGNAME_PREFIX}popup-el-0.5.9
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=auto-complete/}
GITHUB_PROJECT=	popup-el
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/popup-el-0.5.9

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/auto-complete/popup-el/
COMMENT=	Visual popup interface library for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/popup

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/popup

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
