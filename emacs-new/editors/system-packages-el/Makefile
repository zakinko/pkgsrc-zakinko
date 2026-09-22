# $NetBSD$

DISTNAME=	system-packages-1.1.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}system-packages-el-1.1.2
CATEGORIES=	editors
MASTER_SITES=	https://gitlab.com/jabranham/system-packages/-/archive/${PKGVERSION_NOREV}/
EXTRACT_SUFX=	.tar.bz2

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://gitlab.com/jabranham/system-packages/
COMMENT=	Manage your installed packages with Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/system-packages

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/system-packages

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
