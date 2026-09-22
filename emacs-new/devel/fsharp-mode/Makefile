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
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/fsharp-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
