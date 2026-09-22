# $NetBSD$

DISTNAME=	volume-1.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}volume-el-1.0
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=dbrock/}
GITHUB_PROJECT=	volume.el
GITHUB_TAG=	050d3e6d2543a6771a13f95612055864679b6301
WRKSRC=		${WRKDIR}/volume.el-050d3e6d2543a6771a13f95612055864679b6301

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/dbrock/volume.el
COMMENT=	Tweak your sound card volume from Emacs
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/volume

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/volume

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
