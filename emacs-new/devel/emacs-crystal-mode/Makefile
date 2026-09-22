# $NetBSD$

DISTNAME=	emacs-crystal-mode-0.2.0.20260111
PKGNAME=	${EMACS_PKGNAME_PREFIX}emacs-crystal-mode-0.2.0.20260111
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=crystal-lang-tools/}
GITHUB_PROJECT=	emacs-crystal-mode
GITHUB_TAG=	559e1d8ff9bb87a4e937978001386bfb58b113a0
WRKSRC=		${WRKDIR}/emacs-crystal-mode-559e1d8ff9bb87a4e937978001386bfb58b113a0

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/crystal-lang-tools/emacs-crystal-mode/
COMMENT=	GNU Emacs major mode for editing Crystal programming language files
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}flycheck-mode-[0-9]*:../../textproc/flycheck-mode

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/emacs-crystal-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/emacs-crystal-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
