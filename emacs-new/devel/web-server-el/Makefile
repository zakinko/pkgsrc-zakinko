# $NetBSD$

DISTNAME=	web-server-0.1.2.20210708
PKGNAME=	${EMACS_PKGNAME_PREFIX}web-server-el-0.1.2.20210708
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=eschulte/}
GITHUB_PROJECT=	emacs-web-server
GITHUB_TAG=	6357a1c2d1718778503f7ee0909585094117525b
WRKSRC=		${WRKDIR}/emacs-web-server-6357a1c2d1718778503f7ee0909585094117525b

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/eschulte/emacs-web-server/
COMMENT=	Web server running Emacs Lisp handlers
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/web-server

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/web-server

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
