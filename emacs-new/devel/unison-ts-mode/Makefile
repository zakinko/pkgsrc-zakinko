# $NetBSD$

DISTNAME=	unison-ts-mode-0.3.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}unison-ts-mode-0.3.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=fmguerreiro/}
GITHUB_PROJECT=	unison-ts-mode
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/fmguerreiro/unison-ts-mode/
COMMENT=	GNU Emacs major mode for the Unison language that uses Tree-sitter
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-libs/tree-sitter-unison

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/unison-ts-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/unison-ts-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
