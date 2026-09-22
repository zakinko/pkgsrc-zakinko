# $NetBSD$

DISTNAME=	desktop-file-utils-0.28
PKGNAME=	${EMACS_PKGNAME_PREFIX}desktop-entry-mode-0.28
CATEGORIES=	devel
MASTER_SITES=	https://www.freedesktop.org/software/desktop-file-utils/releases/
MASTER_SITES+=	https://distfiles.gentoo.org/distfiles/35/
EXTRACT_SUFX=	.tar.xz
# misc/desktop-entry-mode.el from desktop-file-utils; sysutils/desktop-file-utils does not install it
WRKSRC=		${WRKDIR}/${DISTNAME}/misc

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://gitlab.freedesktop.org/xdg/desktop-file-utils
COMMENT=	GNU Emacs mode for handling freedesktop.org desktop entry files
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-util/desktop-file-utils-0.28

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/desktop-entry-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile desktop-entry-mode.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} desktop-entry-mode.el ${DESTDIR}${EMACS_LISPPREFIX}/desktop-entry-mode
	cd ${WRKSRC} && for f in desktop-entry-mode.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/desktop-entry-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
