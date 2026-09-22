# $NetBSD$

DISTNAME=	doom-themes-2.3.0.20231208
PKGNAME=	${EMACS_PKGNAME_PREFIX}doom-themes-2.3.0.20231208
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=doomemacs/}
GITHUB_PROJECT=	themes
GITHUB_TAG=	ff26f26ea3d761375f5fc4070438fbd0f3473d33
WRKSRC=		${WRKDIR}/themes-ff26f26ea3d761375f5fc4070438fbd0f3473d33

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/doomemacs/themes/
COMMENT=	Opinionated megapack of modern color-themes for GNU Emacs
LICENSE=	mit

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/doom-themes

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/doom-themes

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
