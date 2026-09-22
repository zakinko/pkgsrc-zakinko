# $NetBSD$

DISTNAME=	raku-mode-0.2.1.20211121
PKGNAME=	${EMACS_PKGNAME_PREFIX}raku-mode-0.2.1.20211121
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=Raku/}
GITHUB_PROJECT=	raku-mode
GITHUB_TAG=	977b14a7c1295ebf2aad2f807d3f8e7c27aeb47f
WRKSRC=		${WRKDIR}/raku-mode-977b14a7c1295ebf2aad2f807d3f8e7c27aeb47f

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/Raku/raku-mode/
COMMENT=	Major mode for editing Raku code
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/raku-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/raku-mode
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/raku-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
