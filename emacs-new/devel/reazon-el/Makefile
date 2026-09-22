# $NetBSD$

DISTNAME=	reazon-0.4.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}reazon-el-0.4.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=nickdrozd/}
GITHUB_PROJECT=	reazon
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/nickdrozd/reazon/
COMMENT=	GNU Emacs implementation of miniKanren, logic programming language
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/reazon

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/reazon

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
