# $NetBSD$

DISTNAME=	eldoc-box-1.14.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}eldoc-box-el-1.14.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=casouri/}
GITHUB_PROJECT=	eldoc-box
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/casouri/eldoc-box
COMMENT=	Child frame doc for Eglot and anything that uses ElDoc
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/eldoc-box

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/eldoc-box

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
