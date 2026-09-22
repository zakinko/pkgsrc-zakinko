# $NetBSD$

DISTNAME=	racket-mode-1.20260303
PKGNAME=	${EMACS_PKGNAME_PREFIX}racket-mode-1.20260303
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=greghendershott/}
GITHUB_PROJECT=	racket-mode
GITHUB_TAG=	e5f22ad408740ec517a436ec19b74ce1398e61bc
WRKSRC=		${WRKDIR}/racket-mode-e5f22ad408740ec517a436ec19b74ce1398e61bc

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://www.racket-mode.com/
COMMENT=	Emacs modes for Racket: edit, REPL, check-syntax, debug, profile, and 
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
# XXX Gentoo also depends on dev-scheme/racket

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/racket-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/racket-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
