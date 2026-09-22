# $NetBSD$

DISTNAME=	atomic-chrome-2.0.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}atomic-chrome-el-2.0.0
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=alpha22jp/}
GITHUB_PROJECT=	atomic-chrome
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/alpha22jp/atomic-chrome
COMMENT=	Edit text area on Chrome with Emacs using Atomic Chrome
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}websocket-el-[0-9]*:../../devel/websocket-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/atomic-chrome

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/websocket -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/atomic-chrome
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/atomic-chrome; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
