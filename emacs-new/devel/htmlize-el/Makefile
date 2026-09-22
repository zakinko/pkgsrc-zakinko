# $NetBSD$

DISTNAME=	htmlize-1.59
PKGNAME=	${EMACS_PKGNAME_PREFIX}htmlize-el-1.59
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=emacsorphanage/}
GITHUB_PROJECT=	htmlize
GITHUB_TAG=	release/1.59
WRKSRC=		${WRKDIR}/htmlize-release-1.59

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.emacswiki.org/emacs/Htmlize
COMMENT=	HTML-ize font-lock buffers in Emacs
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/htmlize

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/htmlize
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/htmlize; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
