# $NetBSD$

DISTNAME=	eimp-1.4.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}eimp-el-1.4.0
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=nicferrier/}
GITHUB_PROJECT=	eimp
GITHUB_TAG=	2e7536fe6d8f7faf1bad7a8ae37faba0162c3b4f
WRKSRC=		${WRKDIR}/eimp-2e7536fe6d8f7faf1bad7a8ae37faba0162c3b4f

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/nicferrier/eimp/
COMMENT=	Emacs Image Manipulation Package
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on media-gfx/imagemagick

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/eimp

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/eimp
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/eimp; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
