# $NetBSD$

DISTNAME=	mocker-0.5.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}mocker-el-0.5.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=sigma/}
GITHUB_PROJECT=	mocker.el
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/mocker.el-0.5.0

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/sigma/mocker.el/
COMMENT=	Simple mocking framework for Emacs
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/mocker

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/mocker

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
