# $NetBSD$

DISTNAME=	d-mode-2.0.12
PKGNAME=	${EMACS_PKGNAME_PREFIX}d-mode-2.0.12
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=Emacs-D-Mode-Maintainers/}
GITHUB_PROJECT=	Emacs-D-Mode
GITHUB_TAG=	${PKGVERSION_NOREV}
WRKSRC=		${WRKDIR}/Emacs-D-Mode-2.0.12

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/Emacs-D-Mode-Maintainers/Emacs-D-Mode
COMMENT=	Emacs major mode for editing D code
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/d-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/d-mode
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/d-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
