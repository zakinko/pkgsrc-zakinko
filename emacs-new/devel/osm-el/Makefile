# $NetBSD$

DISTNAME=	osm-2.5
PKGNAME=	${EMACS_PKGNAME_PREFIX}osm-el-2.5
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=minad/}
GITHUB_PROJECT=	osm
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/minad/osm/
COMMENT=	OpenStreetMap tile-based viewer for GNU Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on app-editors/emacs-
DEPENDS+=	curl-[0-9]*:../../www/curl
DEPENDS+=	${EMACS_PKGNAME_PREFIX}compat-el-[0-9]*:../../devel/compat-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/osm

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/compat -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/osm

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
