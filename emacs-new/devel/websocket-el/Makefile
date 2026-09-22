# $NetBSD$

DISTNAME=	websocket-1.16
PKGNAME=	${EMACS_PKGNAME_PREFIX}websocket-el-1.16
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=ahyatt/}
GITHUB_PROJECT=	emacs-websocket
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/emacs-websocket-1.16

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/ahyatt/emacs-websocket/
COMMENT=	A websocket implementation in elisp
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/websocket

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/websocket

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
