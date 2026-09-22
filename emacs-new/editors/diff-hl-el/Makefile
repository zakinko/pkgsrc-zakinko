# $NetBSD$

DISTNAME=	diff-hl-1.10.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}diff-hl-el-1.10.0
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=dgutov/}
GITHUB_PROJECT=	diff-hl
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/dgutov/diff-hl/
COMMENT=	Highlight uncommitted changes, jump between and revert them selectivel
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/diff-hl

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/diff-hl

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
