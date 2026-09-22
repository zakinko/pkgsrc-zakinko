# $NetBSD$

DISTNAME=	spinner-1.7.4
PKGNAME=	${EMACS_PKGNAME_PREFIX}spinner-el-1.7.4
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=Malabarba/}
GITHUB_PROJECT=	spinner.el
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/spinner.el-1.7.4

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/Malabarba/spinner.el
COMMENT=	Emacs mode-line spinner for operations in progress
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/spinner

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/spinner

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
