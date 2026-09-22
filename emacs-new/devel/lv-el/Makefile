# $NetBSD$

DISTNAME=	lv-0.15.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}lv-el-0.15.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=abo-abo/}
GITHUB_PROJECT=	hydra
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/hydra-0.15.0

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/abo-abo/hydra/
COMMENT=	Other echo area
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/lv

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/lv

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
