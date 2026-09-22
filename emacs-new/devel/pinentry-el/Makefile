# $NetBSD$

DISTNAME=	pinentry-0.1.20250408
PKGNAME=	${EMACS_PKGNAME_PREFIX}pinentry-el-0.1.20250408
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=ueno/}
GITHUB_PROJECT=	pinentry-el
GITHUB_TAG=	0079964a1dde954ccb2ce8a28613d8020c549a36
WRKSRC=		${WRKDIR}/pinentry-el-0079964a1dde954ccb2ce8a28613d8020c549a36

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/ueno/pinentry-el
COMMENT=	GnuPG Pinentry server implementation for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on app-crypt/pinentry

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/pinentry

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/pinentry

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
