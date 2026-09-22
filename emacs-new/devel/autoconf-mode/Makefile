# $NetBSD$

DISTNAME=	autoconf-2.72
PKGNAME=	${EMACS_PKGNAME_PREFIX}autoconf-mode-2.72
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GNU:=autoconf/}
MASTER_SITES+=	https://distfiles.gentoo.org/distfiles/81/
EXTRACT_SUFX=	.tar.xz
# autoconf-mode.el and autotest-mode.el from the autoconf tarball; devel/autoconf does not install them
WRKSRC=		${WRKDIR}/${DISTNAME}/lib/emacs

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.gnu.org/software/autoconf/autoconf.html
COMMENT=	Emacs major modes for editing autoconf and autotest input
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/autoconf-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/autoconf-mode
	cd ${WRKSRC} && for f in *.elc; do \
		test ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/autoconf-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
