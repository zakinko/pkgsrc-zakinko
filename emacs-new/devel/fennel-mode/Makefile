# $NetBSD$

DISTNAME=	fennel-mode-0.9.2
PKGNAME=	${EMACS_PKGNAME_PREFIX}fennel-mode-0.9.2
CATEGORIES=	devel
MASTER_SITES=	https://git.sr.ht/~technomancy/fennel-mode/archive/
DISTFILES=	${PKGVERSION_NOREV}${EXTRACT_SUFX}
DIST_SUBDIR=	${DISTNAME}

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://git.sr.ht/~technomancy/fennel-mode/
COMMENT=	Emacs support for the Fennel programming language
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/fennel-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/fennel-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
