# $NetBSD$

DISTNAME=	color-browser-0.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}color-browser-el-0.3
CATEGORIES=	devel
MASTER_SITES=	https://distfiles.gentoo.org/distfiles/06/
EXTRACT_SUFX=	.tar.gz
# an old library that Gentoo keeps on its own mirror; upstream is gone

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/KahlilHodgson
COMMENT=	A utility for designing Emacs color themes
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}color-theme-[0-9]*:../../misc/color-theme

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/color-browser

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/color-theme -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/color-browser

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
