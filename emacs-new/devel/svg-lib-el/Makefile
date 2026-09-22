# $NetBSD$

DISTNAME=	svg-lib-0.3
PKGNAME=	${EMACS_PKGNAME_PREFIX}svg-lib-el-0.3
CATEGORIES=	devel
MASTER_SITES=	https://dev.gentoo.org/~arsen/
EXTRACT_SUFX=	.tar.xz
# upstream is gone; Gentoo keeps the file on its developers' mirror

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/rougier/svg-lib
COMMENT=	SVG tags, progress bars & icons
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/svg-lib

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/svg-lib
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/svg-lib; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
