# $NetBSD$

DISTNAME=	espuds-0.3.3.20171111
PKGNAME=	${EMACS_PKGNAME_PREFIX}espuds-el-0.3.3.20171111
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=ecukes/}
GITHUB_PROJECT=	espuds
GITHUB_TAG=	78fc53feaf77a98d63894cd410faee2a18107b00
WRKSRC=		${WRKDIR}/espuds-78fc53feaf77a98d63894cd410faee2a18107b00

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/ecukes/espuds/
COMMENT=	Common step definitions for Emacs Ecukes
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}dash-el-[0-9]*:../../devel/dash-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}f-el-[0-9]*:../../devel/f-el
DEPENDS+=	${EMACS_PKGNAME_PREFIX}s-el-[0-9]*:../../devel/s-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/espuds

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/dash -L ${EMACS_LISPPREFIX}/f -L ${EMACS_LISPPREFIX}/s -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/espuds

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
