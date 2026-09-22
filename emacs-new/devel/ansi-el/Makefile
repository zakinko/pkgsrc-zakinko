# $NetBSD$

DISTNAME=	ansi-0.4.1.20211104
PKGNAME=	${EMACS_PKGNAME_PREFIX}ansi-el-0.4.1.20211104
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=rejeep/}
GITHUB_PROJECT=	ansi.el
GITHUB_TAG=	2367fba7b3b2340364a30cd6de7f3eb6bb9898a3
WRKSRC=		${WRKDIR}/ansi.el-2367fba7b3b2340364a30cd6de7f3eb6bb9898a3

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/rejeep/ansi.el/
COMMENT=	Emacs library to convert strings into ansi
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/ansi

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/ansi

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
