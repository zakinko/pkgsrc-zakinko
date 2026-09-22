# $NetBSD$

DISTNAME=	bm-202506
PKGNAME=	${EMACS_PKGNAME_PREFIX}bm-el-202506
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=joodland/}
GITHUB_PROJECT=	bm
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://joodland.github.io/bm/
COMMENT=	Visible bookmarks in buffer
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/bm

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/bm

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
