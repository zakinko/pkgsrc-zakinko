# $NetBSD$

DISTNAME=	spacemacs-theme-0.3.20241101
PKGNAME=	${EMACS_PKGNAME_PREFIX}spacemacs-theme-el-0.3.20241101
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=nashamri/}
GITHUB_PROJECT=	spacemacs-theme
GITHUB_TAG=	6c74684c4d55713c8359bedf1936e429918a8c33
WRKSRC=		${WRKDIR}/spacemacs-theme-6c74684c4d55713c8359bedf1936e429918a8c33

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/nashamri/spacemacs-theme/
COMMENT=	Emacs color theme that started as a theme for Spacemacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/spacemacs-theme

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/spacemacs-theme
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/spacemacs-theme; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
