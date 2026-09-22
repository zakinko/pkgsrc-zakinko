# $NetBSD$

DISTNAME=	yatex1.84
PKGNAME=	${EMACS_PKGNAME_PREFIX}yatex-el-1.84
CATEGORIES=	devel
MASTER_SITES=	http://www.yatex.org/
MASTER_SITES+=	https://distfiles.gentoo.org/distfiles/2b/
EXTRACT_SUFX=	.tar.gz

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	http://www.yatex.org/
COMMENT=	Yet Another TeX mode for Emacs
LICENSE=	2-clause-bsd

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/yatex

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

# yahtml.el reads yatex variables at compile time, so yatex is loaded first;
# yatex19.el and yatex23.el (menus for windowed Emacs 19/23) refuse to
# compile in batch and stay source
do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -l yatex -f batch-byte-compile $$(ls *.el | grep -v "^yatex19.el$$" | grep -v "^yatex23.el$$")

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/yatex
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/yatex; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
