# $NetBSD$

DISTNAME=	yasnippet-0.14.3.20250604
PKGNAME=	${EMACS_PKGNAME_PREFIX}yasnippet-el-0.14.3.20250604
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=joaotavora/}
GITHUB_PROJECT=	yasnippet
GITHUB_TAG=	c1e6ff23e9af16b856c88dfaab9d3ad7b746ad37
WRKSRC=		${WRKDIR}/yasnippet-c1e6ff23e9af16b856c88dfaab9d3ad7b746ad37

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://joaotavora.github.io/yasnippet/
COMMENT=	Yet another snippet extension for Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/yasnippet

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/yasnippet
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/yasnippet; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
