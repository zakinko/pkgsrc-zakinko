# $NetBSD$

DISTNAME=	dired-sort-menu-1.26
PKGNAME=	${EMACS_PKGNAME_PREFIX}dired-sort-menu-el-1.26
CATEGORIES=	devel
MASTER_SITES=	https://distfiles.gentoo.org/distfiles/77/
EXTRACT_SUFX=	.tar.gz
# an old library that Gentoo keeps on its own mirror; upstream is gone

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/DiredSortMenu
COMMENT=	Sort entries in Dired mode
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/dired-sort-menu

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/dired-sort-menu

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
