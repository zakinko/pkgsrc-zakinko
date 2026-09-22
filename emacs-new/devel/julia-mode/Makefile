# $NetBSD$

DISTNAME=	julia-mode-0.4.20211023
PKGNAME=	${EMACS_PKGNAME_PREFIX}julia-mode-0.4.20211023
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=JuliaEditorSupport/}
GITHUB_PROJECT=	julia-emacs
GITHUB_TAG=	47f43f7d839019cac3ba6559d93b29487ca118cb
WRKSRC=		${WRKDIR}/julia-emacs-47f43f7d839019cac3ba6559d93b29487ca118cb

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/JuliaEditorSupport/julia-emacs/
COMMENT=	Emacs major mode for the Julia programming language
LICENSE=	mit

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/julia-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/julia-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
