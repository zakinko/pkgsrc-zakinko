# $NetBSD$

DISTNAME=	fsharp-mode-2.0.20230622
PKGNAME=	${EMACS_PKGNAME_PREFIX}fsharp-mode-2.0.20230622
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=fsharp/}
GITHUB_PROJECT=	emacs-fsharp-mode
GITHUB_TAG=	b4d31c3da018cfbb3d1f9e6fd416d8777f0835bd
WRKSRC=		${WRKDIR}/emacs-fsharp-mode-b4d31c3da018cfbb3d1f9e6fd416d8777f0835bd

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/fsharp/emacs-fsharp-mode/
COMMENT=	Support for the F# programming language
LICENSE=	apache-2.0

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/fsharp-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/fsharp-mode
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/fsharp-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
