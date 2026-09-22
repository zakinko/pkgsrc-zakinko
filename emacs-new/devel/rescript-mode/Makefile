# $NetBSD$

DISTNAME=	rescript-mode-0.1.0.20220613
PKGNAME=	${EMACS_PKGNAME_PREFIX}rescript-mode-0.1.0.20220613
CATEGORIES=	devel
MASTER_SITES=	${MASTER_SITE_GITHUB:=jjlee/}
GITHUB_PROJECT=	rescript-mode
GITHUB_TAG=	2aae2fbd4971dff965c758ec19688780ed7bff21
WRKSRC=		${WRKDIR}/rescript-mode-2aae2fbd4971dff965c758ec19688780ed7bff21

MAINTAINER=	pkgsrc-users@NetBSD.org
HOMEPAGE=	https://github.com/jjlee/rescript-mode/
COMMENT=	Emacs major mode for ReScript
LICENSE=	gnu-gpl-v3

EMACS_VERSIONS_ACCEPTED=	emacs29 emacs29nox emacs30 emacs30nox emacs31 emacs31nox

INSTALLATION_DIRS=	${EMACS_LISPPREFIX}/rescript-mode

post-extract:
	cd ${WRKSRC} && ${RM} -f *-test.el *-tests.el *-subtest.el test-*.el tests-*.el *-testsuite.el .dir-locals.el

do-build:
	cd ${WRKSRC} && ${EMACS_BIN} --no-init-file --no-site-file -batch \
		-L .  -f batch-byte-compile *.el

# files marked no-byte-compile leave no .elc behind
do-install:
	cd ${WRKSRC} && ${INSTALL_DATA} *.el ${DESTDIR}${EMACS_LISPPREFIX}/rescript-mode
	cd ${WRKSRC} && for f in *.elc; do \
		${TEST} ! -f "$$f" || ${INSTALL_DATA} "$$f" ${DESTDIR}${EMACS_LISPPREFIX}/rescript-mode; done

.include "../../editors/emacs/modules.mk"
.include "../../mk/bsd.pkg.mk"
