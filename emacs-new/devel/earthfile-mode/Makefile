# $NetBSD$

DISTNAME=	earthfile-mode-0.1.0.20230810
PKGNAME=	${EMACS_PKGNAME_PREFIX}earthfile-mode-0.1.0.20230810
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=earthly/}
GITHUB_PROJECT=	earthly-emacs
GITHUB_TAG=	3029e5ab06171ca5947041e95053561e10e5ba41
WRKSRC=		${WRKDIR}/earthly-emacs-3029e5ab06171ca5947041e95053561e10e5ba41

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/earthly/earthly-emacs/
COMMENT=	GNU Emacs major mode for editing Earthly Earthfiles
LICENSE=	mpl-2.0

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/earthfile-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/earthfile-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
