# $NetBSD$

DISTNAME=	joplin-mode-202401009.2024
PKGNAME=	${EMACS_PKGNAME_PREFIX}joplin-mode-202401009.2024
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=cinsk/}
GITHUB_PROJECT=	joplin-mode
GITHUB_TAG=	08d68e776eaf46b59f9b00bce0a40e52b7e406c7
WRKSRC=		${WRKDIR}/joplin-mode-08d68e776eaf46b59f9b00bce0a40e52b7e406c7

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/cinsk/joplin-mode/
COMMENT=	GNU Emacs client for accessing Joplin notes
LICENSE=	gnu-gpl-v2

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox
DEPENDS+=	${EMACS_PKGNAME_PREFIX}markdown-mode-[0-9]*:../../textproc/markdown-mode

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/joplin-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/joplin-mode
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/joplin-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
