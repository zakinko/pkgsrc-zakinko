# $NetBSD$

DISTNAME=	clatter-0.8.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}clatter-el-0.8.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=parenworks/}
GITHUB_PROJECT=	clatter.el
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/clatter.el-0.8.1

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/parenworks/clatter.el/
COMMENT=	An IRCv3-compliant IRC client for GNU Emacs
LICENSE=	mit

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/clatter

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/clatter

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
