# $NetBSD$

DISTNAME=	sunrise-commander-6.20210927
PKGNAME=	${EMACS_PKGNAME_PREFIX}sunrise-commander-el-6.20210927
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=sunrise-commander/}
GITHUB_PROJECT=	sunrise-commander
GITHUB_TAG=	16e6df7e86c7a383fb4400fae94af32baf9cb24e
WRKSRC=		${WRKDIR}/sunrise-commander-16e6df7e86c7a383fb4400fae94af32baf9cb24e

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/Sunrise_Commander/
COMMENT=	Twin-pane file manager for Emacs inspired by Midnight Commander
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/sunrise-commander

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/sunrise-commander

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
