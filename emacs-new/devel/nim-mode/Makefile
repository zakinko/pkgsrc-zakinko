# $NetBSD$

DISTNAME=	nim-mode-0.4.2.20231101
PKGNAME=	${EMACS_PKGNAME_PREFIX}nim-mode-0.4.2.20231101
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=nim-lang/}
GITHUB_PROJECT=	nim-mode
GITHUB_TAG=	1338e5b0d5e111ad932efb77d3cad680cc3b86c9
WRKSRC=		${WRKDIR}/nim-mode-1338e5b0d5e111ad932efb77d3cad680cc3b86c9

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/nim-lang/nim-mode/
COMMENT=	Emacs major mode for the Nim programming language support
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}commenter-el-[0-9]*:../../devel/commenter-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}epc-el-[0-9]*:../../devel/epc-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/nim-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/commenter -L ${EMACS_LISPPREFIX}/epc -L ${EMACS_LISPPREFIX}/ctable -L ${EMACS_LISPPREFIX}/deferred -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/nim-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
