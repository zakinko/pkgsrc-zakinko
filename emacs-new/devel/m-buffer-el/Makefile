# $NetBSD$

DISTNAME=	m-buffer-0.16.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}m-buffer-el-0.16.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=phillord/}
GITHUB_PROJECT=	m-buffer-el
GITHUB_TAG=	5e7714835b2289f61dad24c0b5cf98d28fc313b0
WRKSRC=		${WRKDIR}/m-buffer-el-5e7714835b2289f61dad24c0b5cf98d28fc313b0

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/phillord/m-buffer-el/
COMMENT=	List Oriented Buffer Operations for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/m-buffer

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/m-buffer

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
