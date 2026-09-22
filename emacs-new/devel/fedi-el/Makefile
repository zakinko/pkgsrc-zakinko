# $NetBSD$

DISTNAME=	fedi.el-0.4
PKGNAME=	${EMACS_PKGNAME_PREFIX}fedi-el-0.4
CATEGORIES=	devel
MASTER_SITES=	https://codeberg.org/martianh/fedi.el/archive/
DISTFILES=	${PKGVERSION_NOREV}${EXTRACT_SUFX}
DIST_SUBDIR=	${DISTNAME}
WRKSRC=		${WRKDIR}/fedi.el

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://codeberg.org/martianh/fedi.el/
COMMENT=	Helper functions for Fediverse or other REST API clients for GNU Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on app-editors/emacs-
DEPENDS+=	${EMACS_PKGNAME_PREFIX}markdown-mode-[0-9]*:../../textproc/markdown-mode

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/fedi

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/fedi

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
