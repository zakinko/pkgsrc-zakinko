# $NetBSD$

DISTNAME=	vw-mode-d9c537065074f5752458f481a09faa93b244ce05
PKGNAME=	${EMACS_PKGNAME_PREFIX}vw-mode-1.0.20250609
CATEGORIES=	devel
MASTER_SITES=	https://git.sr.ht/~jemarch/vw-mode/archive/
DISTFILES=	d9c537065074f5752458f481a09faa93b244ce05${EXTRACT_SUFX}
DIST_SUBDIR=	${DISTNAME}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://git.sr.ht/~jemarch/vw-mode/
COMMENT=	Major mode for editing VW Grammars for GNU Emacs
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/vw-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/vw-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
