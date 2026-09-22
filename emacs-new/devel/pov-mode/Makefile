# $NetBSD$

DISTNAME=	pov-mode-3.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}pov-mode-3.3
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=emacsmirror/}
GITHUB_PROJECT=	pov-mode
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/melmothx/pov-mode
COMMENT=	Major mode for Povray scene files
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/pov-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/pov-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
