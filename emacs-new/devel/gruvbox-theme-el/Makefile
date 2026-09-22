# $NetBSD$

DISTNAME=	gruvbox-theme-1.30.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}gruvbox-theme-el-1.30.3
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=greduan/}
GITHUB_PROJECT=	emacs-theme-gruvbox
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/emacs-theme-gruvbox-1.30.3

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/greduan/emacs-theme-gruvbox/
COMMENT=	Gruvbox is a retro groove color scheme, now in Emacs
LICENSE=	mit

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}autothemer-el-[0-9]*:../../editors/autothemer-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/gruvbox-theme

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/autothemer -L ${EMACS_LISPPREFIX}/dash -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/gruvbox-theme

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
