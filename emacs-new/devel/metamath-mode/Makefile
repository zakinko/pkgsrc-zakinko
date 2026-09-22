# $NetBSD$

DISTNAME=	metamath-mode-0.20221005
PKGNAME=	${EMACS_PKGNAME_PREFIX}metamath-mode-0.20221005
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=samrushing/}
GITHUB_PROJECT=	metamath-mode
GITHUB_TAG=	85bd63b88378e9f2dee2f7d5585ec6610bf098a6
WRKSRC=		${WRKDIR}/metamath-mode-85bd63b88378e9f2dee2f7d5585ec6610bf098a6

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/samrushing/metamath-mode/
COMMENT=	Major GNU Emacs mode for metamath files
LICENSE=	mit

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/metamath-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L . -f batch-byte-compile *.el

do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el *.elc \
		${DESTDIR}${EMACS_LISPPREFIX}/metamath-mode

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
