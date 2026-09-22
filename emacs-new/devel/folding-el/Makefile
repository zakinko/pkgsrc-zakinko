# $NetBSD$

DISTNAME=	folding-2019.0524.1621
PKGNAME=	${EMACS_PKGNAME_PREFIX}folding-el-2019.0524.1621
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=jaalto/}
GITHUB_PROJECT=	project-emacs--folding-mode
GITHUB_TAG=	a1361aa154b27bd4db2e1cfe6c3b81b4fc1fdc9a
WRKSRC=		${WRKDIR}/project-emacs--folding-mode-a1361aa154b27bd4db2e1cfe6c3b81b4fc1fdc9a

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/FoldingMode
COMMENT=	folding-editor-like Emacs minor mode
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/folding

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/folding
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/folding; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
