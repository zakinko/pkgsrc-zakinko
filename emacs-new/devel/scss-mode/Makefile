# $NetBSD$

DISTNAME=	scss-mode-0.5.0.20180123
PKGNAME=	${EMACS_PKGNAME_PREFIX}scss-mode-0.5.0.20180123
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=antonj/}
GITHUB_PROJECT=	scss-mode
GITHUB_TAG=	cf58dbec5394280503eb5502938f3b5445d1b53d
WRKSRC=		${WRKDIR}/scss-mode-cf58dbec5394280503eb5502938f3b5445d1b53d

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/antonj/scss-mode/
COMMENT=	Major mode for editing SCSS files in Emacs
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-ruby/sass

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/scss-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/scss-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
