# $NetBSD$

DISTNAME=	xterm-color-2.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}xterm-color-el-2.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=atomontage/}
GITHUB_PROJECT=	xterm-color
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/atomontage/xterm-color/
COMMENT=	ANSI and xterm-256 color text property translator for GNU Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/xterm-color

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/xterm-color

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
