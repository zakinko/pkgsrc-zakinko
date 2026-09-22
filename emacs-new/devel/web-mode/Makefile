# $NetBSD$

DISTNAME=	web-mode-17.3.20
PKGNAME=	${EMACS_PKGNAME_PREFIX}web-mode-17.3.20
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=fxbois/}
GITHUB_PROJECT=	web-mode
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://web-mode.org/
COMMENT=	Web template editing mode for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/web-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/web-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
