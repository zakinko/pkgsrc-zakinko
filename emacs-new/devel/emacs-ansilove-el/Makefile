# $NetBSD$

DISTNAME=	emacs-ansilove-2.0.0
PKGNAME=	${EMACS_PKGNAME_PREFIX}emacs-ansilove-el-2.0.0
CATEGORIES=	devel
MASTER_SITES=	https://gitlab.com/xgqt/emacs-ansilove/-/archive/${PKGVERSION_NOREV}/
EXTRACT_SUFX=	.tar.bz2
WRKSRC=		${WRKDIR}/${DISTNAME}/src

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://gitlab.com/xgqt/emacs-ansilove/
COMMENT=	Display buffers as PNG images using ansilove in GNU Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on app-editors/emacs-
# XXX Gentoo also depends on media-gfx/ansilove
# XXX Gentoo also depends on media-gfx/imagemagick

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/emacs-ansilove

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/emacs-ansilove
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/emacs-ansilove; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
