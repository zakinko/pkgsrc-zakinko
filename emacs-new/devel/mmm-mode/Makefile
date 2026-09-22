# $NetBSD$

DISTNAME=	mmm-mode-0.5.11
PKGNAME=	${EMACS_PKGNAME_PREFIX}mmm-mode-0.5.11
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=dgutov/}
GITHUB_PROJECT=	mmm-mode
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	http://mmm-mode.sourceforge.net/
COMMENT=	Enables the user to edit different parts of a file in different major 
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/mmm-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/mmm-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
