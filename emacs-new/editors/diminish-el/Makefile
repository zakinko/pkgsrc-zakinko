# $NetBSD$

DISTNAME=	diminish-0.46pre20220128
PKGNAME=	${EMACS_PKGNAME_PREFIX}diminish-el-0.46pre20220128
CATEGORIES=	editors
MASTER_SITES=	${MASTER_SITE_GITHUB:=myrjola/}
GITHUB_PROJECT=	diminish.el
GITHUB_TAG=	6b7e837b0cf0129e9d7d6abae48093cf599bb9e8
WRKSRC=		${WRKDIR}/diminish.el-6b7e837b0cf0129e9d7d6abae48093cf599bb9e8

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/myrjola/diminish.el/
COMMENT=	Hiding or abbreviation of the mode line displays (lighters)
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/diminish

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/diminish
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/diminish; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
