# $NetBSD$

DISTNAME=	treesit-auto-1.0.9
PKGNAME=	${EMACS_PKGNAME_PREFIX}treesit-auto-el-1.0.9
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=renzmann/}
GITHUB_PROJECT=	treesit-auto
GITHUB_TAG=	v${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/renzmann/treesit-auto/
COMMENT=	Automatic installation, usage, fallback for tree-sitter modes in Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on app-editors/emacs

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/treesit-auto

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/treesit-auto
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/treesit-auto; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
