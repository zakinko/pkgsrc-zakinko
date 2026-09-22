# $NetBSD$

DISTNAME=	thinks-1.13
PKGNAME=	${EMACS_PKGNAME_PREFIX}thinks-el-1.13
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=davep/}
GITHUB_PROJECT=	thinks.el
GITHUB_TAG=	v${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/thinks.el-1.13

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.davep.org/emacs/
COMMENT=	Insert text in a think bubble
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/thinks

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/thinks

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
