# $NetBSD$

DISTNAME=	polymode-0.2.2.20260505
PKGNAME=	${EMACS_PKGNAME_PREFIX}polymode-el-0.2.2.20260505
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=polymode/}
GITHUB_PROJECT=	polymode
GITHUB_TAG=	8cb72fa5dcc0d98746c680043dc121edc7621e3a
WRKSRC=		${WRKDIR}/polymode-8cb72fa5dcc0d98746c680043dc121edc7621e3a

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/polymode/polymode/
COMMENT=	Framework for Multiple Major Modes in Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/polymode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/polymode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
