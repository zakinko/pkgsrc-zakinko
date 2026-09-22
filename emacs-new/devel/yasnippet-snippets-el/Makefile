# $NetBSD$

DISTNAME=	yasnippet-snippets-1.1
PKGNAME=	${EMACS_PKGNAME_PREFIX}yasnippet-snippets-el-1.1
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=AndreaCrotti/}
GITHUB_PROJECT=	yasnippet-snippets
GITHUB_TAG=	${PKGVERSION_NOREV}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/AndreaCrotti/yasnippet-snippets
COMMENT=	A collection of yasnippet snippets for many languages
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}yasnippet-el-[0-9]*:../../devel/yasnippet-el

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/yasnippet-snippets

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -L ${EMACS_LISPPREFIX}/yasnippet -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/yasnippet-snippets

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
